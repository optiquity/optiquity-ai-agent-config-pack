# AGENTS.md

This configuration is for Xcode 26.3's Codex integration.
It mirrors the repo-level policy but lives in the user-local Xcode customization directory:
  ~/Library/Developer/Xcode/CodingAssistant/codex/

Do not commit this file into app repositories. It is user-local.

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

- SwiftUI first. UIKit or AppKit interop only when justified.
- SPM first. No CocoaPods unless unavailable in SPM.
- Swift 6 strict concurrency for new code.

## Design rules

- Prefer immutable types by default.
- Mark classes `final` unless subclassing is required.
- Make invalid states unrepresentable.
- Keep SwiftUI views thin.
- Prefer dependency injection over global state.
- Avoid force unwraps outside tightly justified cases.

## gRPC client rules

When the active project communicates with a first-party backend over gRPC:
- Never call gRPC stubs from ViewModels or Views.
- Auth tokens in gRPC metadata, never in message fields.
- Every gRPC call has an explicit deadline using a named constant.
- Never hand-edit generated Protobuf or gRPC Swift code.

## Agent behavior

- Read existing code before adding new abstractions.
- Do not invent package APIs or Xcode settings.
- Prefer the smallest correct change.
- State uncertainty explicitly.
- When using a local model, avoid high-risk changes unless a stronger model has already reviewed the plan.
