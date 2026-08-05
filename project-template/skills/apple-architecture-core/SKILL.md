---
name: apple-architecture-core
description: Use for patterns shared across all Apple platforms — SwiftUI-first design, protocol abstractions at boundaries, layer discipline, typed IDs, LSP compliance, capabilities pattern, SPM module structure, deployment-target compatibility.
allowed-tools: Read, Grep, Glob, Bash
---

## Companion skill — Swift concurrency rules

Substantive concurrency design — actor isolation, `@MainActor` and
global-actor selection, Sendable conformance, structured concurrency,
AsyncSequence / AsyncStream patterns, GCD, GCD ↔ async-await
modernization — lives in `swift-concurrency-patterns`. That skill
loads as D1-implied for D1 ∈ {ios, macos} alongside this one. This
skill carries the architectural-state-ownership rules that touch
concurrency only at a glance (see "State ownership" below); the
actor-isolation rules and reentrancy pitfalls are in the companion.

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
construction time, not at call time. Example: a `Device` protocol
declares `var capabilities: DeviceCapabilities { get }` where
`DeviceCapabilities` is an `OptionSet` (`.read`, `.write`,
`.stream`, …). Callers check
`device.capabilities.contains(.stream)` before invoking the
streaming call.

13. **Interface-based form in Swift.** Split behavior into small,
focused protocols. A type adopts only the protocols it genuinely
supports. Callers query with a downcast to the capability protocol
(`if let streaming = device as? StreamingSensorProvider { … }`), never
to the concrete type. Compose protocols via protocol inheritance or
generic constraints (`where Device: StreamingSensorProvider`). Do not
emulate capabilities by throwing from stub conformances — a type that
does not stream must not conform to `StreamingSensorProvider` at all.

14. **Where capability validation belongs.** Initializers of the
composing type (hub ⇠ device, controller ⇠ device, sensor
aggregator ⇠ provider) reject incompatible pairings at construction
time. Call sites query capabilities only for behavior that legitimately
varies across conforming types — never as a substitute for
LSP-compliant method implementations.

## State ownership

15. Shared mutable state documents its owner, isolation domain (owning actor, thread, or queue), lifecycle, and mutation contract at the definition site. Substantive actor-isolation rules — when to choose `actor` vs `@MainActor` vs a global actor, reentrancy across `await`, isolated parameters — live in `swift-concurrency-patterns`.
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

## Animation correctness

28. Animations are state-driven, not imperative. Bind animation to a SwiftUI state change with `withAnimation { … }` (when several state changes should animate together) or with `.animation(_, value:)` (when one state change drives the animation). Do not reach for `UIView.animate(withDuration:)` from SwiftUI code paths; use the imperative UIKit/AppKit animation APIs only inside `UIViewRepresentable` / `NSViewRepresentable` wrappers per `ios-architecture` rule 12. Snap transitions caused by a missing `withAnimation` wrapper around a state mutation are a defect, not a stylistic choice.
29. Respect Reduce Motion. Read `\.accessibilityReduceMotion` (SwiftUI) or `UIAccessibility.isReduceMotionEnabled` (UIKit) and degrade gracefully — substitute crossfade for slide / scale, eliminate parallax, disable autoplay, drop spring overshoot. Reduce Motion is a correctness requirement, not a polish item; ignoring it is a defect. Performance anti-patterns (animations on the main thread that block scrolling, layout thrash from animating large hierarchies during scroll) are auditor-code's lane per `audit-methodology` rule 16; animation *shape* — implicit-vs-explicit choice, missing `withAnimation`, missing Reduce Motion fallback — is auditor-ui's lane via this rule.

## Liquid Glass design language (iOS 26+ / macOS 26+)

30. When the project's deployment target supports it, Liquid Glass is the platform-correct design language for translucent / vibrant surfaces. Use `.glassEffect()` and the system material APIs (`.regularMaterial`, `.thinMaterial`, `.ultraThinMaterial`, `.thickMaterial`, `.ultraThickMaterial`) rather than reimplementing equivalent surfaces with custom `UIVisualEffectView`, ad-hoc blur layers, or hand-painted translucent fills. A custom material that duplicates a system surface is a defect. All Liquid Glass calls require `#available(iOS 26, *)` / `#available(macOS 26, *)` guards per rule 22 when the deployment target is below iOS 26 / macOS 26.
31. Do not paint solid colors or opaque overlays directly on top of a Liquid Glass surface — it defeats the design intent (the surface is meant to read through to whatever sits behind it). Compose translucency with translucency: layered materials and vibrancy effects, not solid fills. Test every Liquid Glass surface in both light and dark mode AND with the "Increase Contrast" accessibility preference enabled — Liquid Glass surfaces can fail contrast guidelines in some configurations, and the platform-correct fix is a vibrancy adjustment, not abandoning the material.
