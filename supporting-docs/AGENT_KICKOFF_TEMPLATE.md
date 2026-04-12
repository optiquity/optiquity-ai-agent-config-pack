# AGENT_KICKOFF_TEMPLATE.md — Architecture Phase Kickoff Prompt Template

<!--
HOW TO USE THIS TEMPLATE

This is a fill-in-the-blanks template for generating a project-specific AGENT_KICKOFF.md.

1. The PM chat generates AGENT_KICKOFF.md by reading this template and filling in
   all [PLACEHOLDER] values based on the project planning conversation.
2. The resulting AGENT_KICKOFF.md goes in the project repo root.
3. Paste its full contents into a CLI session to start the architecture phase:
   cd ~/Developer/[PROJECT] && ./agent-run.sh <cli> --agent architect
   Then paste the contents of AGENT_KICKOFF.md as your first message.
4. This template stays in the pack — it is never copied to project repos.

The PM chat should customize, expand, or remove sections based on the actual project.
Not every section applies. Remove what doesn't apply.
-->

---
*Generated from: supporting-docs/AGENT_KICKOFF_TEMPLATE.md — AI Agent Config Pack v9*
*Note to PM chat: Replace all [PLACEHOLDERS] and remove this header before saving.*
---

# [PROJECT_NAME] — Architecture Phase Kickoff

You are the architecture specialist for [PROJECT_NAME].

Read `CLAUDE.md` at the repo root before doing anything else. It contains the project
rules you must follow. Then read `AGENTS.md`. Then proceed with the tasks below.

---

## Project overview

[2-3 sentence description of what the project is, its purpose, and who uses it.]

**Platform:** [e.g., macOS 15+, Xcode 26.3, Swift 6, SwiftUI]
**Architecture pattern:** [e.g., MVVM, TCA, layered with domain/data/presentation separation]
**Build targets:** [e.g., single macOS app, iOS + macOS universal, macOS + watch extension]

---

## External dependencies to read before designing

Before writing ARCHITECTURE.md or any code, read and understand these resources:

<!-- List all external APIs, frameworks, and docs the architect must understand first -->
<!-- Include direct URLs — the agent will fetch them -->

| Resource | URL | Why it matters |
|---|---|---|
| [API/Framework name] | [URL] | [What the agent needs to understand about it] |
| [API/Framework name] | [URL] | [What the agent needs to understand about it] |

[Add or remove rows as needed. Remove this section entirely if no external research is needed.]

---

## Key domain types and protocols

The architecture must define these core types. For each:
- Define it as a protocol in the domain layer
- Provide a stub concrete implementation in the data layer
- Ensure nothing in domain or presentation holds a concrete type directly

<!-- List the primary domain protocols/types for this project -->

| Type | Kind | Description |
|---|---|---|
| [TypeName] | Protocol | [What it represents] |
| [TypeName] | Value type | [What it represents] |
| [TypeName] | Reference type | [What it represents] |

---

## Architecture constraints

These constraints are non-negotiable. The architecture must satisfy all of them.

**Architecture decisions required:** Before producing any stub code, document the chosen
approach AND all rejected alternatives with rationale for each decision below. This
documentation must appear in `ARCHITECTURE.md` at the decision site — not only in
planning conversation output.

- □ Heterogeneous domain collections: type-erasure wrappers / exhaustive enums /
    protocol elevation — which and why
    Note: Type-erasure wrappers that expose a .base accessor for downcasting to a
    concrete type are an LSP violation — they are runtime type interrogation
    disguised as abstraction. Protocol elevation (moving all needed behavior into
    the protocol as requirements) is the preferred approach. Exhaustive enums are
    preferred when the concrete type must be known at the call site and the set of
    types is fixed and internal.
- □ Domain state change notification: coarse broadcast / typed payload streams /
    observation framework — granularity, back pressure, actor-hop cost at expected
    update frequency
    Note: AsyncStream<Void> (contentless broadcast) forces every subscriber to
    perform an actor hop and re-fetch all state on every signal regardless of
    relevance. Typed payload streams (AsyncStream<ChangeType>) allow subscribers
    to filter by relevance before crossing actor boundaries. AsyncChannel from
    swift-async-algorithms is a competing-consumer rendezvous channel — it is NOT
    suitable for fan-out to multiple independent subscribers.
- □ ViewModel-to-navigation coupling: direct navigator injection / route-intent
    stream / closure-based — what the ViewModel emits vs. what the View layer executes
    Note: ViewModels must not import SwiftUI. A ViewModel that imports SwiftUI cannot
    be tested independently of a view hierarchy and violates the framework-independence
    goal. ViewModels must express navigation intent as output that the View layer
    consumes, including a typed stream or observable state property of a
    ViewModel-defined enum, a non-isolated closure injected by the caller, or a
    delegate protocol defined by the ViewModel. The ViewModel never holds or calls
    a navigator directly.
- □ [Add project-specific correctness-sensitive structural decisions here]

<!-- Customize the constraint list below for the project — add, remove, or modify as needed -->

1. **Layer separation:** Separate presentation, domain, and data/transport layers. No layer may skip its immediate neighbor.
2. **Domain isolation:** The domain layer imports nothing from SwiftUI, AppKit, UIKit, [PERSISTENCE_FRAMEWORK], or any networking framework.
3. **Protocol-first:** Every cross-layer dependency is a protocol. Concrete types are injected; never referenced by name in domain or presentation code.
4. **[PROJECT_SPECIFIC_CONSTRAINT_1]:** [Description]
5. **[PROJECT_SPECIFIC_CONSTRAINT_2]:** [Description]

[Add project-specific constraints. Remove the placeholder rows.]

---

## Required output — Part 1: ARCHITECTURE.md

Write `ARCHITECTURE.md` at the repo root. It must cover:

1. **Chosen architecture pattern** — name it, explain why it fits this project
2. **Layer map** — which types and files live in which layer
3. **Key protocol definitions** — interface for each domain protocol listed above
4. **[PROJECT_SPECIFIC_SECTION]** — [e.g., "Data persistence strategy", "Streaming design", "Authentication model"]
5. **Known limitations and future migration path** — any current shortcuts with documented upgrade paths
6. **Dependency decisions** — what third-party packages are used, why, and exit plan

---

## Required output — Part 2: Stub hierarchy

After ARCHITECTURE.md is complete and the layer map is settled, generate the stub
Swift (or Python) files. For each major type:

**Protocols** — full interface definition with all methods and properties
**Domain model types** — complete definition with all fields (no logic needed)
**Stub implementations** — bare minimum: satisfies the protocol, no errors, no real behavior
**[PROJECT_SPECIFIC_STUB_TYPE]** — [e.g., "ViewModels with all @Published properties and empty method bodies"]

<!-- Customize this list based on the architecture -->

Stubs to generate:
- [ ] [StubName] — [brief description]
- [ ] [StubName] — [brief description]
- [ ] [StubName] — [brief description]

---

## Required output — Part 3: Test infrastructure

Create the test target(s) and foundational test infrastructure:

- [ ] [TestTargetName] — [unit / integration / UI]
- [ ] [MockName] — mock for [protocol name]
- [ ] [MockName] — mock for [protocol name]

[Add or remove based on what the architecture requires. Remove this section if
the architecture phase is not responsible for test target creation.]

---

## Verification

After completing all output:

1. Run `./scripts/validate.sh` (or `xcodebuild build` / `swift build` as appropriate)
2. Confirm: zero compiler errors, zero warnings
3. Confirm: every stub compiles cleanly
4. Report: files created, any open design questions or risks

Do not mark the phase complete if the project does not build clean.

---

## Important constraints

- Do not write production logic in this phase — stubs and protocols only
- Do not add SPM dependencies unless CLAUDE.md specifically permits them in this phase
- Do not modify CLAUDE.md, AGENTS.md, or any file not listed above
- If you discover a design question that requires a decision, stop and ask rather than assuming
