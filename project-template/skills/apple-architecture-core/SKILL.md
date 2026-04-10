---
name: apple-architecture-core
description: Use for patterns shared across all Apple platforms — SwiftUI-first design, protocol abstractions at boundaries, actor isolation, typed IDs, LSP compliance, SPM module structure.
allowed-tools: Read, Grep, Glob, Bash
---

## SwiftUI-first design

1. SwiftUI is the default UI framework. UIKit or AppKit interop requires documented justification: missing SwiftUI capability, performance requirement, or mature third-party framework exposing only UIKit/AppKit API.
2. Keep views thin. Domain logic and orchestration live in dedicated types, not in view bodies.
3. ViewModels must not import SwiftUI or hold navigation references. Express navigation intent as typed output consumed by the view layer.

## Layer discipline

4. Separate presentation, domain, and data/transport layers. No layer reaches past its immediate neighbor.
5. Domain layer has zero import dependencies on UIKit, AppKit, SwiftUI, CoreData, SwiftData, or any networking framework.
6. Every cross-layer dependency is a protocol abstraction. Concrete implementations are injected.
7. Generated Protobuf and gRPC types live in the data layer only. They never appear in domain or presentation type signatures.

## Protocol abstractions

8. Prefer protocols at layer boundaries, not everywhere. Over-abstracting internal implementation creates noise.
9. Every protocol method must have a meaningful implementation in every conforming type. Silent no-ops are LSP violations.
10. No domain or presentation code may branch on the concrete type behind a protocol reference.

## Actor isolation and state

11. Shared mutable state documents its owner, owning actor or thread, lifecycle, and mutation contract.
12. Services are stateless by default. Stateful services document their state variables and threading guarantees.
13. Avoid singleton sprawl. Document ownership and lifecycle of all shared state.

## Typed identifiers

14. Persistent domain objects carry a typed ID wrapper (UUID wrapped in a named struct). Never use raw UUID or String at domain boundaries.
15. Stringly-typed identifiers and state machines are anti-patterns.

## SPM module structure

16. Divide the app into independently compilable Swift packages where module boundaries align with architectural layers or feature domains.
17. Module dependencies must follow the layer hierarchy — a domain module never imports a presentation or data module.

## Architecture documentation

18. Choose one primary architecture pattern per app target. Document the choice and rationale in ARCHITECTURE.md before writing production code.
19. Mixed-pattern seams within a target require explicit documentation and justification.
20. Navigation logic lives outside view and view-model types. Use Coordinator, NavigationStack with typed path, or Router depending on the chosen pattern.
