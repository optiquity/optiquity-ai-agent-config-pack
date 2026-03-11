---
name: architecture-review
description: Use when assessing architecture across the Apple client, Python server, or the gRPC/Proto3 schema boundary.
allowed-tools: Read, Grep, Glob, Bash
---

For Apple client work:
1. Identify modules, layers, and seams.
2. Check whether SwiftUI-first remains viable.
3. Require justification for UIKit or AppKit interop.
4. Check state ownership, immutability, and dependency boundaries.
5. Verify gRPC stubs are behind protocols, never called from ViewModels or Views.
6. Check gRPC channel lifecycle is tied to app or scene lifecycle.

For Python server work:
1. Verify gRPC servicers are thin adapters delegating to injected service objects.
2. Check constructor DI is used. Flag module-level globals as service registries.
3. Verify async design: no blocking I/O in async handlers.
4. Check input validation at I/O boundaries.
5. Check type annotation completeness.
6. Flag N+1 query risks.

For the shared schema boundary:
1. Verify proto field numbers have never been reused.
2. Verify buf lint and buf breaking are part of the merge process.
3. Check that generated code is never hand-edited.

Give a recommendation with explicit tradeoffs.

## Layer Boundary Review

Apply these checks on all architecture reviews:

1. Verify domain layer has no imports of UIKit, AppKit, SwiftUI, CoreData, SwiftData, GRPCCore, grpcio, or any networking framework.
2. Verify generated Protobuf types do not appear in domain-layer or presentation-layer type signatures.
3. Verify every cross-layer dependency is expressed as a protocol; concrete types are injected.
4. Verify shared mutable state has documented ownership: owner type, actor/thread, lifecycle, and mutation contract.
5. Verify navigation logic is not embedded in View or ViewModel types.
6. Verify services are stateless or explicitly document their state and threading guarantees.
7. Verify the architecture pattern is documented (README or ARCHITECTURE.md) before flagging pattern inconsistencies.
