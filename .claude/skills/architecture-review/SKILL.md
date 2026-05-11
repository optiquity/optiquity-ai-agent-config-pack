---
name: architecture-review
description: Use when assessing architecture — module boundaries, layer discipline, state ownership, dependency decisions, and long-term maintainability. Platform-agnostic assessment methodology.
allowed-tools: Read, Grep, Glob, Bash
---

This skill defines the universal methodology for architecture review. Platform-specific rules come from the platform skills loaded alongside this one (apple-architecture-core, python-server-architecture, python-data-architecture, grpc-patterns, etc.). Apply this methodology using the rules from those skills.

## Before starting the review

1. Read `ARCHITECTURE.md` to understand the project's documented architecture pattern, layer map, and rationale. If it does not exist, flag this as a blocking issue — architecture reviews require a documented baseline.
2. Identify the modules, layers, and seams present in the codebase. Map what exists against what `ARCHITECTURE.md` describes.
3. Identify which platform skills are relevant to the code under review and apply their rules during the assessment.

## Layer discipline

4. Verify layer separation: presentation, domain, and data/transport are distinct types, files, or modules. No layer may reach past its immediate neighbor.
5. Verify the domain layer has no framework imports (UI frameworks, persistence frameworks, networking frameworks). This is a verifiable import-graph property — flag any violation as a defect.
6. Verify every cross-layer dependency is expressed as a protocol or interface abstraction. Concrete implementations are injected; they are never instantiated inline by the consuming layer.
7. Verify transport types (generated Protobuf, serialization DTOs) live only in the data layer. They must never appear in domain-layer or presentation-layer type signatures.

## State ownership

8. Verify shared mutable state documents its owner type, owning actor or thread, lifecycle (creation and destruction), and mutation contract. Undocumented shared mutable state is a defect.
9. Verify services are stateless by default. Stateful services document their state variables, threading guarantees, and invalidation policy at the definition site.
10. Flag singleton sprawl — shared state accessed globally without clear ownership is an architecture smell.

## Abstraction quality

11. Flag over-abstraction — protocols or interfaces at every internal boundary create noise without improving testability. Abstractions belong at layer boundaries, not within layers.
12. Flag under-abstraction — concrete types from the data layer appearing in domain or presentation code violates layer discipline.
13. Verify LSP compliance: every protocol method must have a meaningful implementation in every conforming type. Silent no-ops and unconditional "not supported" throws are violations. No domain or presentation code may branch on the concrete type behind a protocol reference.

## Navigation and control flow

14. Verify navigation and routing logic is not embedded in view or view-model types. Navigation belongs in a dedicated coordinator, router, or typed navigation path — the exact pattern is determined by the project's platform and the loaded platform skills.

## Dependency decisions

15. Evaluate third-party dependencies for architectural impact. Flag dependencies that shape the architecture in unwanted ways — a dependency that forces a specific concurrency model, data layer, or UI framework is an architectural decision, not just a package choice. Detailed evaluation criteria live in the `dependency-intake` skill.

## Output

- Assessment of each layer: what exists, whether it matches `ARCHITECTURE.md`, and any violations.
- List of findings grouped by severity (critical / major / minor). Each finding includes the file and symbol, the rule violated, and the recommended action.
- Rejected-alternative documentation: when proposing a change, name the alternatives considered and why they were rejected.
- Explicit tradeoffs: every architectural decision has costs — name them.
