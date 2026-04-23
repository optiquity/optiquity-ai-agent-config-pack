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

## Capabilities pattern

11. Make what a type supports explicit and queryable. Callers do not
discover unsupported operations through `fatalError`, `throw`, or
`switch` on concrete types. Reach for this pattern proactively during
architecture — not only when fixing an LSP violation. LSP is required; the capabilities pattern is a recommended best practice.
Apply each on its own merits.

12. **Value-based form in Swift.** Expose supported operations as an
`OptionSet` (bitmask), a `Set<Enum>` of a focused operation enum, or a
frozen struct of `Bool` flags, exposed on the abstraction as a
read-only property. Validate capability compatibility at the
*composing* type's initializer — reject incompatible pairings at
construction time, not at call time. Example: a `Broker` protocol
declares `var capabilities: BrokerCapabilities { get }` where
`BrokerCapabilities` is an `OptionSet` (`.placeOrder`, `.cancelOrder`,
`.streamQuotes`, …). Callers check
`broker.capabilities.contains(.streamQuotes)` before invoking the
streaming call.

13. **Interface-based form in Swift.** Split behavior into small,
focused protocols. A type adopts only the protocols it genuinely
supports. Callers query with a downcast to the capability protocol
(`if let streaming = broker as? StreamingQuoteProvider { … }`), never
to the concrete type. Compose protocols via protocol inheritance or
generic constraints (`where Broker: StreamingQuoteProvider`). Do not
emulate capabilities by throwing from stub conformances — a type that
does not stream must not conform to `StreamingQuoteProvider` at all.

14. **Where capability validation belongs.** Initializers of the
composing type (account ⇠ broker, order router ⇠ broker, quote
aggregator ⇠ provider) reject incompatible pairings at construction
time. Call sites query capabilities only for behavior that legitimately
varies across conforming types — never as a substitute for
LSP-compliant method implementations.

## Actor isolation and state

15. Shared mutable state documents its owner, owning actor or thread, lifecycle, and mutation contract.
16. Services are stateless by default. Stateful services document their state variables and threading guarantees.
17. Avoid singleton sprawl. Document ownership and lifecycle of all shared state.

## Typed identifiers

18. Persistent domain objects carry a typed ID wrapper (UUID wrapped in a named struct). Never use raw UUID or String at domain boundaries.
19. Stringly-typed identifiers and state machines are anti-patterns.

## SPM module structure

20. Divide the app into independently compilable Swift packages where module boundaries align with architectural layers or feature domains.
21. Module dependencies must follow the layer hierarchy — a domain module never imports a presentation or data module.

## Deployment target compatibility

22. Every use of an API introduced in an OS version newer than the project's minimum deployment target must be wrapped in `#available(iOS N, macOS N, *)` guards or annotated with `@available(iOS N, macOS N, *)`. Using a newer API unconditionally on an older deployment target is a crash. This includes OS-version-specific APIs like `.glassEffect()`, `FoundationModels`, and any other API documented as "Available in iOS N+".
23. When adding availability guards, verify the fallback code path produces equivalent user-visible behavior, not just a silent no-op.
24. The project's minimum deployment target is documented in `ARCHITECTURE.md` or the project's build configuration. Reviewers and auditors flag any API usage that exceeds the documented minimum without an explicit guard.

## Architecture documentation

25. Choose one primary architecture pattern per app target. Document the choice and rationale in ARCHITECTURE.md before writing production code.
26. Mixed-pattern seams within a target require explicit documentation and justification.
27. Navigation logic lives outside view and view-model types. Use Coordinator, NavigationStack with typed path, or Router depending on the chosen pattern.
