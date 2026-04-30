# PLATFORM-SKILLS.md — Skill Selection Matrix

This file is the PM chat's authoritative reference for selecting which skills
to load when generating agent prompts. Read this file at prompt-generation time.

---

## How skill selection works

Every agent prompt includes two categories of skills:

1. **Tier 1 role skills** — define how the agent performs its role. Always
   available in the template. The PM chat loads only those relevant to the
   active task (e.g., `python-architecture` is not loaded for a Swift-only
   architect pass).

2. **Tier 2 platform skills** — encode platform-specific rules, patterns, and
   constraints. Selected by combining the four dimensions below.

The PM chat combines both categories when generating a prompt:
*"Use the {role skill} skill. Also load {platform skill 1}, {platform skill 2}."*

---

## Step 1 — Build the project's skill profile

Answer four questions about the project. Each answer adds skills to the set.
If a skill is added by more than one dimension, it is loaded once (deduplicate).

### Dimension 1 — Platform targets

What OS or platform does the software run on?

| Selection | Skills added |
|---|---|
| iOS | apple-architecture-core, ios-architecture, deployment-apple |
| macOS | apple-architecture-core, macos-architecture, deployment-apple |
| iOS + macOS (universal) | apple-architecture-core, ios-architecture, macos-architecture, deployment-apple |

Skills that appear in multiple rows (apple-architecture-core, deployment-apple)
are added once regardless of how many Apple platforms the project targets.

Future platforms (add row when skills are created):
Android, Web, Windows, Embedded Linux.

### Dimension 2 — Languages

What programming languages are in the codebase?

| Selection | Skills added |
|---|---|
| Swift | swift-best-practices, dependency-swift |
| Python | python-best-practices, dependency-python |
| C | c-language |
| C++ | cpp-language |
| Objective-C | objc-language |

Select all languages present. Each adds its own skills independently.

Future languages (add row when skills are created):
Kotlin, TypeScript/JavaScript, C#, Rust.

### Dimension 3 — Component roles

What architectural role does each component play? Most projects have one role.
Monorepos and multi-component systems may have several.

| Selection | Skills added | When to use |
|---|---|---|
| Python server | python-architecture, deployment-python | Python serves requests (gRPC, REST, or other protocol) |
| Embedded Python | c-language | Python runtime embedded inside another application (C API is the bridge) |
| Shared native library | (none additional) | C or C++ library consumed by other components — Language skills cover it |

A Role entry adds a dedicated architecture skill only when ALL three conditions
are true: (1) the role introduces structural patterns (service layers, handler
delegation, middleware, lifecycle) not covered by any Language or Protocol skill;
(2) the patterns are role-specific — they exist because of what the component
does, not what language or protocol it uses; (3) the patterns are substantial
(10+ items). If Language + Protocol skills fully cover the role, the Role row
adds nothing or adds an existing skill. If the patterns are protocol-specific,
add a section to the existing Protocol skill instead.
See V9-DESIGN.md Decision 7 for full extension rules.

Future roles (add row when skills are created):
Swift server (Vapor/Hummingbird), Node.js server.

### Dimension 4 — Communication protocols

How do components communicate with each other?

| Selection | Skills added |
|---|---|
| gRPC | grpc-patterns |
| REST | rest-patterns |
| No inter-component communication | (none) |

Select all protocols in use. A project using both gRPC (internal) and REST
(third-party) loads both skills.

Future protocols (add row when skills are created):
GraphQL, WebSocket/SSE (realtime-patterns), Webhooks/AMQP (messaging-patterns), SOAP.

### Combining dimensions — worked examples

**iOS Swift app, no server:**
- Platform: iOS → apple-architecture-core, ios-architecture, deployment-apple
- Language: Swift → swift-best-practices, dependency-swift
- Role: client app → (none additional)
- Protocol: none → (none)
- **Result:** apple-architecture-core, ios-architecture, deployment-apple, swift-best-practices, dependency-swift

**Python gRPC server:**
- Platform: Linux → (no platform architecture skills)
- Language: Python → python-best-practices, dependency-python
- Role: Python server → python-architecture, deployment-python
- Protocol: gRPC → grpc-patterns
- **Result:** python-best-practices, dependency-python, python-architecture, deployment-python, grpc-patterns

**Universal Apple app + Python gRPC server (monorepo):**
- Platform: iOS + macOS → apple-architecture-core, ios-architecture, macos-architecture, deployment-apple
- Language: Swift + Python → swift-best-practices, dependency-swift, python-best-practices, dependency-python
- Role: client app + Python server → python-architecture, deployment-python
- Protocol: gRPC → grpc-patterns
- **Result:** apple-architecture-core, ios-architecture, macos-architecture, deployment-apple, swift-best-practices, dependency-swift, python-best-practices, dependency-python, python-architecture, deployment-python, grpc-patterns

**macOS Swift app with embedded Python:**
- Platform: macOS → apple-architecture-core, macos-architecture, deployment-apple
- Language: Swift + Python → swift-best-practices, dependency-swift, python-best-practices, dependency-python
- Role: embedded Python → c-language
- Protocol: none → (none)
- **Result:** apple-architecture-core, macos-architecture, deployment-apple, swift-best-practices, dependency-swift, python-best-practices, dependency-python, c-language

**macOS Swift app with C++ performance code:**
- Platform: macOS → apple-architecture-core, macos-architecture, deployment-apple
- Language: Swift + C++ → swift-best-practices, dependency-swift, cpp-language
- Role: client app → (none additional)
- Protocol: none → (none)
- **Result:** apple-architecture-core, macos-architecture, deployment-apple, swift-best-practices, dependency-swift, cpp-language

---

## Step 2 — Select skills per agent

For each agent prompt, load the agent's Tier 1 role skills plus the Tier 2
platform skills from Step 1 that are relevant to that agent's work. Not every
agent needs every platform skill — load only what the agent's role requires.

### Agents and their skill assignments

**architect**
- Tier 1: architecture-review, api-design
- Tier 2 (from Step 1): apple-architecture-core, ios-architecture, macos-architecture, swift-best-practices, python-best-practices, python-architecture, grpc-patterns, rest-patterns, c-language, objc-language, cpp-language — load those present in the project's skill profile

**coder**
- Tier 1: implementation, debugging, error-handling
- Tier 2 (from Step 1): swift-best-practices, python-best-practices, grpc-patterns, rest-patterns, c-language, objc-language, cpp-language — load those present in the project's skill profile

**reviewer**
- Tier 1: review, error-handling
- Tier 2 (from Step 1): swift-best-practices, python-best-practices, python-architecture, grpc-patterns, rest-patterns, apple-architecture-core, ios-architecture, macos-architecture, c-language, objc-language, cpp-language, security-patterns — load those present in the project's skill profile

**tester**
- Tier 1: testing, ui-test-strategy
- Tier 2 (from Step 1): swift-best-practices, python-best-practices, grpc-patterns, rest-patterns, ios-architecture, macos-architecture, c-language, objc-language, cpp-language — load those present in the project's skill profile (language skills for framework/naming conventions and test double patterns; protocol skills for transport-level test harnesses; platform architecture skills for UI test surface knowledge)

**planner**
- Tier 1: planning

**repo-ops**
- Tier 1: repo-ops

**docs-researcher**
- Tier 1: documentation, dependency-intake
- Tier 2 (from Step 1): deployment-apple, deployment-python, dependency-swift, dependency-python — load those present in the project's skill profile

**grpc-schema**
- Tier 1: api-design
- Tier 2: grpc-patterns

**auditor** (parent)
- Tier 2: audit-methodology
- The parent auditor only loads `audit-methodology`. Subagents load their own platform skills in their isolated contexts. The PM chat passes the per-subagent skill list in the parent's invocation prompt for the parent to relay to each subagent at spawn time.

**auditor-architecture**
- Tier 2: audit-methodology + architecture platform skills from Step 1 (apple-architecture-core, ios-architecture, macos-architecture, python-architecture)
- Platform filtering: load only the architecture skills that match the project's platform profile from Step 1. A pure Python server loads `python-architecture` only. A pure iOS app loads `apple-architecture-core` + `ios-architecture` only. Observability infrastructure rules live inside these platform architecture skills (no separate observability skill).

**auditor-code**
- Tier 1: error-handling
- Tier 2: audit-methodology + language skills from Step 1 (swift-best-practices, python-best-practices, c-language, objc-language, cpp-language) + python-architecture (when Python server in project — provides performance anti-pattern rules like N+1 query detection)
- The `error-handling` skill provides the cross-cutting error-handling rules (boundary mapping, retry policy uniformity) that this subagent audits at the systemic level. The language skills (`swift-best-practices`, `python-best-practices`) supply the dead-code and unused-import detection rules.

**auditor-tests**
- Tier 1: testing, ui-test-strategy
- Tier 2: audit-methodology + language skills from Step 1 (swift-best-practices, python-best-practices) for test naming conventions and test framework idioms
- Skip `ui-test-strategy` for server-only projects.

**auditor-docs**
- Tier 1: documentation
- Tier 2: audit-methodology
- No platform skills — drift detection is language-agnostic. The `documentation` skill includes the drift-detection rules section that this subagent uses.

**auditor-security**
- Tier 2: audit-methodology, security-patterns + dependency skills from Step 1 (dependency-swift, dependency-python)
- The `security-patterns` skill includes the supply-chain section (CVEs, license compatibility, abandoned packages) that this subagent owns per `audit-methodology` rules 33–34.

**auditor-ui** (skipped for server-only projects)
- Tier 2: audit-methodology + platform architecture skills from Step 1 (apple-architecture-core, ios-architecture, macos-architecture) + swift-best-practices for view code idioms
- Platform filtering: only loaded for projects with a UI layer. The platform architecture skills supply the accessibility, view-thickness, and UI-state rules — no separate accessibility skill.

**auditor-ops** (always runs)
- Tier 2: audit-methodology + deployment skills from Step 1 (deployment-apple, deployment-python)
- Always loaded for every audit because every project deploys somewhere. The deployment skills cover the platform-specific deployment configuration rules and observability *configuration* (vs. observability *infrastructure*, which lives in the architecture skills loaded by `auditor-architecture`).

---

## Step 3 — Generate the prompt

When generating an agent prompt, include the skill loading instruction:

```
Load the following skills for this task:
- {skill-1}
- {skill-2}
- ...
```

The agent reads each skill's SKILL.md at the start of the session. Skills are
located in `.claude/skills/`, `.codex/skills/`, or `.gemini/skills/` depending
on which tool runs the agent.

---

## Full skill inventory

### Tier 1 — Role skills (12)

| Skill | Description | Primary agents |
|---|---|---|
| api-design | API design philosophy, versioning, error design, protocol selection | architect, grpc-schema |
| architecture-review | Platform-agnostic architecture assessment methodology | architect |
| debugging | Root cause methodology, diagnostics, fix verification | coder |
| dependency-intake | Platform-agnostic dependency evaluation methodology | docs-researcher |
| documentation | Platform-agnostic research methodology, drift detection (for audits) | docs-researcher, auditor-docs |
| error-handling | Universal domain error philosophy, retry policy, propagation | coder, reviewer, auditor-code |
| implementation | Code change workflow, concurrency safety, verification | coder |
| planning | Scoping, task breakdown, risk identification, verification strategy | planner |
| repo-ops | Git workflows, scripting, command sequencing, safety | repo-ops |
| review | Review priorities, examination checklist, finding reporting | reviewer |
| testing | Test pyramid, design, organization, coverage | tester, auditor-tests |
| ui-test-strategy | UI/E2E tool selection, test design, snapshot testing | tester, auditor-tests |

### Tier 2 — Platform skills (17)

| Skill | Description | Agents |
|---|---|---|
| apple-architecture-core | Cross-platform Apple patterns, SwiftUI-first, layer discipline | architect, reviewer, auditor-architecture, auditor-ui |
| audit-methodology | Audit report format, severity scale, subagent coordination, file scopes, ownership precedence | auditor (parent + all 7 subagents) |
| c-language | C memory ownership, pointers, buffers, const, Swift/Python interop | architect, coder, reviewer, auditor-code |
| cpp-language | C++ RAII, smart pointers, Swift-C++ interop, rule of five | coder, reviewer, auditor-code |
| dependency-python | PyPI evaluation, wheels, version pinning, type stubs, security | docs-researcher, auditor-security |
| dependency-swift | SPM evaluation, Apple framework alternatives, binary frameworks | docs-researcher, auditor-security |
| deployment-apple | Code signing, entitlements, notarization, privacy manifests, observability config | auditor-ops, docs-researcher |
| deployment-python | Docker, secrets, health checks, graceful shutdown, production config, observability config | auditor-ops, docs-researcher |
| grpc-patterns | Proto3 schema, grpc-swift-2, grpc.aio, cross-language conventions | architect, grpc-schema, coder, reviewer |
| ios-architecture | iOS/iPadOS scene lifecycle, UIKit interop, App Store boundaries, accessibility, observability infrastructure | architect, reviewer, auditor-architecture, auditor-ui |
| macos-architecture | macOS NSDocument, windows, menu bar, AppKit, sandbox, accessibility, observability infrastructure | architect, reviewer, auditor-architecture, auditor-ui |
| objc-language | Objective-C ARC, nullability, bridging, legacy code patterns | coder, reviewer, auditor-code |
| python-architecture | Python server structure, service layers, repository pattern, grpc.aio handlers, observability infrastructure | architect, reviewer, auditor-architecture, auditor-code |
| python-best-practices | Python type hints, async, error handling, ruff/pyright, style, dead code | architect, coder, reviewer, auditor-code |
| rest-patterns | REST/HTTP URL design, HTTP methods, status codes, OpenAPI, caching | architect, coder, reviewer |
| security-patterns | Credential exposure, injection, deserialization, log safety, supply chain (CVEs, licenses) | auditor-security, reviewer |
| swift-best-practices | Swift type system, immutability, Swift 6 concurrency, style, dead code | architect, coder, reviewer, auditor-code, auditor-ui |

### PM chat operational skill (1)

This skill is outside both tiers. It is not loaded by any agent — it is used exclusively by the PM chat itself for session startup and orientation. It exists in the skill directory because the template's skill loading mechanism is uniform across tools, but its purpose is PM chat operational, not agent role guidance.

| Skill | Description | Loaded by |
|---|---|---|
| pm-startup | PM chat session startup procedure: read state files, check TD-TBD sentinels, report ready status | PM chat only (not an agent) |

**Total skills: 30** (12 Tier 1 + 17 Tier 2 + 1 PM chat operational)

### Deferred skills (create when project need arises)

**Platforms:** android-architecture, deployment-android, web-architecture, deployment-web, windows-architecture, deployment-windows, embedded-architecture, deployment-embedded.

**Languages:** kotlin-best-practices, dependency-kotlin, typescript-best-practices, dependency-node, csharp-best-practices, dependency-dotnet, rust-best-practices, dependency-rust.

**Roles:** swift-server-architecture (Vapor/Hummingbird), node-server-architecture.

**Protocols:** graphql-patterns, realtime-patterns (WebSocket/SSE), messaging-patterns (Webhooks/AMQP), soap-patterns.

---

## Extending this file

To add support for a new platform, language, role, or protocol: create the
required skill files, then add rows to the appropriate dimension tables above.
See the dimension extension rules in the pack's design documentation
(V9-DESIGN.md Decision 7) for naming conventions, the governance checklist,
and the criteria for when a new Role needs its own architecture skill.

---

## Custom agents

| Agent | Purpose | Dimension | Phase routed to | Tier 1 skills | Tier 2 skills | Read/write mode |
|---|---|---|---|---|---|---|
| `x-fixture-agent` | FIXTURE-MARKER-CUSTOM-AGENT — reserved for testing | Component Roles | Repo operations | repo-ops | (none) | write |

## Custom skills

| Skill | Description | Dimension | Loaded by |
|---|---|---|---|
| `x-fixture-skill` | FIXTURE-MARKER-CUSTOM-SKILL — reserved for testing | Languages | x-fixture-agent |
