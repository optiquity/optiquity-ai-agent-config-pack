# CLAUDE.md — Xcode 26.3 Claude Agent Configuration
#
# This file lives at:
#   ~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/CLAUDE.md
#
# It applies to every Xcode project on this machine.
# Do NOT commit this file into any app repository. It is user-local.
# Repo-level CLAUDE.md files in each project take precedence for project-specific rules.

## Capability policy

Claude may perform all major engineering tasks in the active Xcode project:
planning, architecture, implementation, refactoring, debugging, testing, code review,
dependency review, repo operations, documentation.

All are allowed. No task category is reserved exclusively for another tool.

Default preference only:
- Use a stronger cloud model for correctness-sensitive work (architecture, concurrency, security, review).
- Use local models only where results are likely equivalent and the verification path is strong.

## Core priorities

1. Correctness before speed.
2. Preserve buildability and testability after every change.
3. Prefer small, reviewable changes over broad rewrites.
4. Keep architecture explicit. Do not hide complexity behind clever abstractions.
5. Verify assumptions against code, tests, docs, or tooling output. Do not guess.

## Platform defaults

- Target platforms: iOS, iPadOS, macOS.
- SwiftUI first. UIKit or AppKit interop only for platform gaps, third-party constraints, or measurable performance reasons.
- Swift Package Manager first. No CocoaPods unless unavailable in SPM.
- Swift 6 strict concurrency for new code. Be pragmatic at legacy and third-party boundaries.

## iOS 26 / Xcode 26.3 platform features

- **Liquid Glass** is the current design language for iOS 26 / macOS 26. Use `.glassEffect()` and related SwiftUI modifiers for materials and visual effects. Prefer this over custom `Material`, `UIVisualEffectView`, or third-party visual effect libraries.
- **FoundationModels** (iOS 26+) is Apple's on-device LLM framework. It is the Apple-first option for language model features. Evaluate it before any third-party ML framework. No network access required.
- **Apple-first dependency rule:** Before recommending any third-party package for a new capability, verify whether an iOS 26 or macOS 26 Apple framework already covers the need. Avoid recommending third-party packages unless they are already in use in the project or no Apple framework addresses the requirement.
- For iOS 26 API details, reference `shared-docs/ios26/` in the local config pack (not in the project repo). Run `sync-xcode-docs.sh` to populate it from the Xcode bundle.

## Design rules

- Prefer immutable types by default.
- Use mutable state only for clearly stateful roles: stores, coordinators, caches, boundary adapters.
- Mark classes `final` unless subclassing is required.
- Make invalid states unrepresentable.
- Keep SwiftUI views thin. Move orchestration elsewhere.
- Prefer dependency injection over global state.
- Avoid force unwraps outside tightly justified cases.

## Architecture — universal layer rules

- Separate presentation, domain, and data/transport layers. No layer skips its immediate neighbor.
- The domain layer has zero import dependencies on UIKit, AppKit, SwiftUI, CoreData, SwiftData, GRPCCore, or any networking or persistence framework.
- Generated Protobuf and gRPC types are transport types. They live in the data layer only. They must never appear in domain-layer or presentation-layer type signatures.
- Every cross-layer dependency is expressed as a protocol. Concrete types are injected.
- Every shared mutable state declaration documents: owner type, owning actor or thread, lifecycle, and mutation contract.
- Services are stateless by default. Stateful services explicitly document their state and threading guarantees.
- Navigation logic lives outside View and ViewModel types.

## gRPC client rules (grpc-swift-2)

This machine uses grpc-swift-2 (https://github.com/grpc/grpc-swift-2) — Swift Concurrency-native.
Do not use grpc-swift v1 APIs in new code.

- Never call generated gRPC stubs directly from ViewModels or Views. Wrap stubs behind a protocol.
- Map Protobuf messages to domain types at the transport boundary. Domain types must never be passed to stubs.
- Never hand-edit generated Protobuf or gRPC Swift code. Regenerate from .proto source.
- Auth tokens in gRPC call metadata, never in Protobuf message fields.
- Every gRPC call must have an explicit deadline using a named constant, not a magic duration literal.
- Map gRPC status codes to typed domain errors at the boundary (catch RPCError, not GRPCStatus).
- Manage one GRPCClient per app or scene lifecycle. Never create channels per request.
- Swift Task cancellation propagates automatically to grpc-swift-2 calls.

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

- Plan first for non-trivial work.
- Call out uncertainty explicitly.
- Do not invent APIs, Apple behavior, package capabilities, or build flags.
- Read existing code before introducing new patterns.
- Prefer the smallest correct change.
- For high-risk changes (concurrency, security, gRPC schema), produce a plan and name remaining risks.
