# CLAUDE.md

This configuration is for Xcode 26.3's Claude Agent integration.
It mirrors the repo-level policy but lives in the user-local Xcode customization directory:
  ~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/

Do not commit this file into app repositories. It is user-local.

## Capability policy

Claude may perform all major engineering tasks in the active Xcode project:
planning, architecture, implementation, refactoring, debugging, testing, code review,
dependency review, repo operations, documentation.

All are allowed. No task category is reserved exclusively for another tool.

Default preference only:
- Use a stronger cloud model for correctness-sensitive work.
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

## Design rules

- Prefer immutable types by default.
- Use mutable state only for clearly stateful roles: stores, coordinators, caches, boundary adapters.
- Mark classes `final` unless subclassing is required.
- Make invalid states unrepresentable.
- Keep SwiftUI views thin. Move orchestration elsewhere.
- Prefer dependency injection over global state.
- Avoid force unwraps outside tightly justified cases.

## gRPC client rules

When the active project communicates with a first-party backend over gRPC:
- Never call gRPC stubs from ViewModels or Views. Wrap stubs behind a protocol.
- Map Protobuf messages to domain types at the transport boundary.
- Auth tokens in gRPC call metadata, never in Protobuf message fields.
- Every gRPC call has an explicit deadline using a named constant.
- Never hand-edit generated Protobuf or gRPC Swift code.

## Agent behavior

- Plan first for non-trivial work.
- Call out uncertainty explicitly.
- Do not invent APIs, Apple behavior, package capabilities, or build flags.
- Read existing code before introducing new patterns.
- Prefer the smallest correct change.
