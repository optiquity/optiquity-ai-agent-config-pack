---
name: architecture-review
description: Use when assessing architecture, module boundaries, concurrency decisions, ownership of mutable state, or whether UIKit or AppKit interop is justified.
---

1. Identify the modules, layers, and ownership boundaries involved.
2. Locate mutable state and decide whether it is justified.
3. Check whether value semantics, final classes, builders, or factories would improve correctness.
4. Check whether the proposed design keeps SwiftUI views thin.
5. Flag dependency, testability, and concurrency risks.
6. Give a recommendation with explicit tradeoffs.

## Layer Boundary Review

Apply these checks on all architecture reviews:

1. Verify domain layer has no imports of UIKit, AppKit, SwiftUI, CoreData, SwiftData, GRPCCore, grpcio, or any networking framework.
2. Verify generated Protobuf types do not appear in domain-layer or presentation-layer type signatures.
3. Verify every cross-layer dependency is expressed as a protocol; concrete types are injected.
4. Verify shared mutable state has documented ownership: owner type, actor/thread, lifecycle, and mutation contract.
5. Verify navigation logic is not embedded in View or ViewModel types.
6. Verify services are stateless or explicitly document their state and threading guarantees.
7. Verify the architecture pattern is documented (README or ARCHITECTURE.md) before flagging pattern inconsistencies.
