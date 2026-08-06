# AGENTS.md

## Capability policy

Codex may perform all major engineering tasks in this repository:
planning, architecture, implementation, refactoring, debugging, testing, code review,
dependency review, repo operations, documentation.

All are allowed. No task category is reserved exclusively for another tool.

Default preference only:
- Use a stronger cloud model for correctness-sensitive work (architecture, concurrency, security, review).
- Use local models only where the verification path is strong and results are likely equivalent.

## Core priorities

1. Correctness before speed.
2. Preserve buildability and testability after every change.
3. Prefer small, reviewable changes over broad rewrites.
4. Keep architecture explicit. Do not hide complexity behind clever abstractions.
5. Verify assumptions against code, tests, docs, or tooling output. Do not guess.

## Platform and stack defaults

<!-- BEGIN project-owned -->
- **Target**: macOS only. No iOS or iPadOS targets in this project.
- **UI**: SwiftUI throughout. No AppKit unless a specific macOS API has no SwiftUI surface.
  Document and isolate any AppKit interop in a clearly named boundary type.
- **Dependencies**: Swift Package Manager only. No CocoaPods. No manual vendoring.
- **Concurrency**: Swift 6 strict concurrency for all new code. Be pragmatic at third-party
  and external API boundaries — isolate unsafe edges explicitly.
- **Build configurations**: Debug and Release only. A four-configuration system
  (Local / Dev / Staging / Production with compiler flags) is a documented future task.
- **Source control**: GitHub. Keep commits small and reviewable.
<!-- END project-owned -->

<!-- BEGIN project-owned: renamed-from "## iOS 26 / Xcode 26.3 platform features" -->
## Xcode 26.4 platform features

This project is built with Xcode 26.4 but targets **macOS 15+**. Any macOS 26 or iOS 26 SDK API must be guarded with `#available(macOS 26, *)` and cannot be used as an unconditional default.

- **Liquid Glass** is the macOS 26 / iOS 26 design language. It is **not available on macOS 15**. Do not use `.glassEffect()` or related modifiers without an `#available(macOS 26, *)` guard. Plan availability-gated adoption when macOS 26 becomes the minimum deployment target.
- **FoundationModels** (macOS 26+) is Apple's on-device LLM framework. Same availability constraint applies. Evaluate before any third-party ML framework when deployment target permits — not a current project requirement.
- **Apple-first dependency rule:** Before recommending any third-party package for a new capability, verify whether a macOS 15+ Apple framework already covers the need. Do not add a dependency when a platform API is sufficient.
- For implementation details on any macOS 26 API, the `docs-researcher` agent reads directly from the Xcode documentation bundle at `/Applications/Xcode.app/Contents/PlugIns/IDEIntelligenceChat.framework/Versions/A/Resources/AdditionalDocumentation/`. If the path does not exist, fall back to web search.
<!-- END project-owned -->

## Architecture — universal layer discipline

These rules apply regardless of which architecture pattern this project uses.

- Choose one primary architecture pattern before writing production code. **Document in `ARCHITECTURE.md` before implementation begins.**
- Separate presentation, domain, and data/transport layers. No layer reaches past its immediate neighbor.
- Domain layer has zero framework imports (no UIKit, AppKit, SwiftUI, gRPC, grpcio).
- Generated Protobuf/gRPC types live in the data layer only — never in domain or presentation signatures.
- Cross-layer dependencies are protocol abstractions. Concrete types are injected.
- Shared mutable state documents its owner, lifecycle, and mutation contract. Undocumented shared mutable state is a defect.
- Services are stateless by default. Stateful services document state, threading, and invalidation.
- Navigation logic lives outside view and view-model types.

<!-- BEGIN project-owned: renamed-from "## Architecture rules — platform-specific", "## Language-specific coding rules" -->
## Swift coding rules

- Prefer structs for models unless reference semantics are required.
- Mark classes `final` by default unless subclassing is explicitly required.
- Make invalid states unrepresentable where possible.
- Prefer typed errors and typed ID wrappers over raw `String` or bare `UUID`.
- Avoid force unwraps except in tightly justified test-only contexts.
- Prefer `async`/`await` over callbacks.
- Any `@MainActor`, `nonisolated`, `Sendable`, or `@unchecked Sendable` decision must be
  intentional and commented when non-obvious.
- Keep SwiftUI views thin. Push domain logic into dedicated types.
- Use dependency injection for all services, stores, and workflow instances.
- Never use `print()` in production code. Use `os_log` or route through `LogSourceGroup`.
<!-- END project-owned -->

## Security

<!-- BEGIN project-owned -->
- Never hardcode secrets, API keys, tokens, or certificates in source code or config files committed to git.
- Validate data received from external or third-party APIs before using in domain logic or UI.
- API keys, OAuth tokens, and certificates: Keychain only. Never in UserDefaults or source.
- Request minimum required entitlements.
<!-- END project-owned -->

## Liskov Substitution Principle

- Every interface or protocol method has a meaningful implementation in every implementing type. Silent no-ops and unconditional "not supported" throws not gated by capability checks are violations.
- No code branches on the concrete type behind an abstract type reference.
- No concrete data-layer type is referenced by name in domain or presentation code.

## Capabilities pattern

Make what a type supports explicit and queryable. Callers check support
before invoking behavior; they do not discover unsupported operations
through exceptions, silent no-ops, or branching on concrete types.
Reach for this pattern during design, not only when fixing an LSP
violation.

The pattern takes two complementary forms:

- **Value-based capabilities.** A type exposes a value (bitmask, flag
  set, enum set, or similar) enumerating the operations it supports.
  Callers check the capability value before invoking the corresponding
  operation. Validate capability compatibility at association or
  initialization time — reject incompatible pairings before they can
  produce runtime errors.
- **Interface-based capabilities.** A type declares conformance to a
  small, focused interface (protocol, trait, abstract base, or
  equivalent) only when it genuinely supports that behavior. Callers
  query for the interface before invoking. Types that do not support a
  behavior simply do not expose the interface — no silent no-ops, no
  unconditional throws.

Both forms share the same intent: make supported behaviors explicit
and queryable. Specific language mechanism varies; design intent is
consistent across any typed system.

**Relationship to LSP.** LSP is required; the capabilities pattern is
recommended. Neither is a prerequisite for the other. They work well
together when both are present.

## Dependency intake policy

<!-- BEGIN project-owned -->
Before adding any third-party package:
1. Check whether Apple frameworks already solve the problem.
2. Prefer actively maintained SPM packages with clear licensing.
3. Evaluate security risk, binary size, lock-in, and long-term maintenance.
4. Record the rationale, alternatives considered, and exit plan in `ARCHITECTURE.md` or a PR note.
5. Third-party charting, plotting, and visualization libraries
   are **deferred** — do not add them until feature requirements are known.
<!-- END project-owned -->

## Testing expectations

<!-- BEGIN project-owned -->
- Unit tests for all domain logic, state machines, capabilities mask logic, invocation rules.
- Use protocol-based test doubles for `DataStore`, `FeedService`, `LogSource`, `Provider`.
  Never use real provider APIs or real persistent stores in unit or integration tests.
- Integration tests at module seams (domain → data layer boundaries).
- XCUITest for UI flows when UI is added.
- Hidden test provider/workflow stubs must compile out of Release builds.
<!-- END project-owned -->

## Refactoring policy

- Do not mix unrelated refactors into feature work.
- Preserve external behavior unless the task explicitly changes behavior.
- When touching legacy code, improve naming, seams, and tests before broad rewrites.
- Prefer deleting dead code over preserving speculative abstractions.

## Skill loading

Agent prompts specify which skills to load. Skills are located in
`.codex/skills/<name>/SKILL.md`. The PM chat selects skills based on
`PLATFORM-SKILLS.md` — the skill-selection matrix for this project.

<!-- BEGIN project-owned -->
**Active skills:** apple-architecture-core, macos-architecture, deployment-apple, swift-best-practices, dependency-swift, rest-patterns
<!-- END project-owned -->

The PM chat checks this list at every phase gate (METHODOLOGY.md Procedure 1).
If an upcoming phase references a technology not covered by the active skills,
the PM chat flags the gap before generating any prompt. Skills are added or
removed by updating this line and the project description above — then committing.

Project-specific (custom) skills use the `x-` prefix and live alongside
pack skills in `.claude/skills/x-<name>/`, `.codex/skills/x-<name>/`, and
`.gemini/skills/x-<name>/`. Pack-supplied skills never begin with `x-`.
See `docs/pack/INSTALL-PROCEDURES.md` § "Project file conventions in
pack-controlled directories" for the full convention and Procedure 5.2
for the creation workflow.

## Document locations

Project documentation is organized into three directories under `docs/`.
All filenames are unique — reference them by name; use these paths to locate them.

| Directory | Contents | Updated by |
|---|---|---|
| `docs/pack/` | `METHODOLOGY.md`, `INSTALL-PROCEDURES.md`, `prompts/`, `PM-CHAT.md`, `PLATFORM-SKILLS.md`, `PACK-FEEDBACK.md` | Pack version updates only (except PACK-FEEDBACK.md — PM chat appends during project) |
| `docs/project/` | `ARCHITECTURE.md`, `IMPLEMENTATION_PLAN.md`, `BACKLOG.md`, `STATUS.md`, `CHANGELOG.md` | PM chat and developer during active development |
| `docs/reference/` | Project-specific user-facing documentation (how-to guides, API references) | Developer as needed |

Root-level files: `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `README.md`, `agent-run.sh`.

## Scripts

`agent-run.sh` lives in the **project root** and is the standard way to launch any agent.
The `scripts/` directory contains build, test, and validation scripts. Make everything
executable on first checkout: `chmod +x agent-run.sh scripts/*.sh`.

| Script | Location | When to run | Who calls it |
|---|---|---|---|
| `agent-run.sh` | Project root | To launch any agent — run `./agent-run.sh --help` | Human only |
| `bootstrap.sh` | `scripts/` | Once on first checkout or new machine — detects languages and calls bootstrap-\<lang\>.sh | Human |
| `bootstrap-swift.sh` | `scripts/` | Resolve SPM dependencies, verify Xcode | `bootstrap.sh` wrapper |
| `bootstrap-python.sh` | `scripts/` | Sync Python dependencies via uv, verify buf | `bootstrap.sh` wrapper |
| `format.sh` | `scripts/` | Before committing — detects languages and calls format-\<lang\>.sh | Human or `repo-ops` agent |
| `format-swift.sh` | `scripts/` | Format Swift sources using swift-format | `format.sh` wrapper |
| `format-python.sh` | `scripts/` | Format Python sources using ruff | `format.sh` wrapper |
| `validate.sh` | `scripts/` | Before committing — full build + test suite; calls validate-\<lang\>.sh | Human or `repo-ops` agent |
| `validate-swift.sh` | `scripts/` | Build and test Swift side | `validate.sh` wrapper |
| `validate-python.sh` | `scripts/` | Lint, type-check, and test Python side | `validate.sh` wrapper |
| `validate-proto.sh` | `scripts/` | Lint proto files and detect breaking changes | `validate.sh` wrapper |
| `test.sh` | `scripts/` | After implementing — runs test suite only; calls test-\<lang\>.sh | Human or `repo-ops` agent |
| `test-swift.sh` | `scripts/` | Run Swift test suite | `test.sh` wrapper |
| `test-python.sh` | `scripts/` | Run Python test suite via pytest | `test.sh` wrapper |
| `proto-gen.sh` | `scripts/` | After editing any `.proto` file — runs buf lint then buf generate | Human or `coder` / `repo-ops` agent |
| `agent-post-edit-check.sh` | `scripts/` | **Never call manually** — fires via Codex post_edit_command and Claude Code PostToolUse hook | Automatic hook |

<!-- BEGIN project-owned -->
**Required first-time setup:** Open `scripts/validate-swift.sh` and `scripts/test-swift.sh` and fill in
the scheme and destination variables for your project. Both are already configured for
SampleApp (`SampleApp` / `platform=macOS`).
<!-- END project-owned -->

## Build and repo hygiene

<!-- BEGIN project-owned -->
- Repo must build from Xcode and `xcodebuild` on a clean checkout.
- Do not commit secrets, generated code, or machine-specific config.
- Do not commit generated Protobuf or gRPC files. Regenerate via `proto-gen.sh`.
- Prefer repo-local scripts over undocumented manual steps.
- Document any new setup step in `README.md`.
- Keep `.gitignore` current.
- **At the end of every implementation phase**, include a **"Proposed CHANGELOG entry"**
  section in your completion report, formatted exactly as it would appear in `CHANGELOG.md`:
  dated header, summary paragraph, itemised task list, files created/modified, and final
  test count. Do not write to `CHANGELOG.md`, `BACKLOG.md`, `README.md`, or any other
  `.md` file in the project root — the PM chat applies these updates after reviewer approval.
<!-- END project-owned -->

## Git workflow

- Make commits small and coherent.
- Include tests when behavior changes.
- Separate mechanical formatting from semantic changes when practical.
- Surface risky migrations early.

## Deferral comments and BACKLOG hygiene

**What you may do:** Add typed deferral comments in code when you encounter work that
cannot be completed within the current phase scope. Report them in your completion report.

**What you may not do:** Write to `BACKLOG.md`, `CHANGELOG.md`, `STATUS.md`,
`PACK-FEEDBACK.md`, or any other `.md` file in the project root — these are
exclusively the PM chat's responsibility. Do not resolve or modify existing BACKLOG
entries. Never write to `PACK-FEEDBACK.md` under any circumstance — it is the
PM chat's upstream feedback log for the AI Agent Config Pack itself.

**Deferral comment syntax** — use the marker for the language you are writing
(`//` for Swift/C/C++/Objective-C, `#` for Python):
```
// TODO(scope): TD-TBD — Short title
// KNOWN GAP(critical|functional|polish): TD-TBD — Short title
// VERIFY(source): TD-TBD — Short title
```
Always write `TD-TBD`. Never invent a TD number.

**Valid scope values for TODO:** `phase-N`, `dependency`, `feature`, `perf`, `version`
**Valid severity values for KNOWN GAP:** `critical`, `functional`, `polish`
**Source for VERIFY:** name the external source (e.g. `apple-docs`, `vendor-api`)

Never use plain English deferral comments (`// Fix later`, `// Confirm this`).
When citing a code location in a report, use the symbol name not the line number.

**BACKLOG write permissions by agent:**

| Agent | May do | May not do |
|---|---|---|
| `coder` | Write TD-TBD comments; report in completion report | Write to BACKLOG.md |
| `reviewer` | Read only | Write anything |
| `docs-researcher` | Read only | Write anything |
| `repo-ops` | Read only | Write anything |

<!-- BEGIN project-owned -->
## Anti-patterns — never introduce these

- Domain types in data-layer or transport-layer signatures.
- `Provider`, `Collection`, `FeedService`, `DataStore`, or `LogSource` concrete types
  referenced directly in presentation or domain code (always go through protocol).
- Hard deletion of user-modifiable objects (use tombstoning).
- `isOn = true` as a default for any `WorkflowSchedule`.
- API keys or tokens stored outside Keychain.
- `print()` in production code.
- Force unwraps as a laziness shortcut.
- Singleton sprawl for injectable services.
- Mutable global state not documented as such.
- `@unchecked Sendable` without a documented and audited justification.
- Blocking the main thread with synchronous I/O.
- SwiftData model types leaking into domain or presentation layers.
- Stringly-typed identifiers or state machines.
- Massive view controllers or God ViewModels accumulating unrelated logic.
- Calling generated gRPC stubs directly from ViewModels or Views.
- Type-erasure wrappers that expose a `.base` property for downcasting to a
  concrete type. Any code of the form `anyWrapper.base as? ConcreteType` in
  domain or presentation code is an LSP violation — it is runtime type
  interrogation disguised as abstraction. Use protocol elevation or exhaustive
  enums instead. In this project, the capability system is the established
  implementation of protocol elevation for provider, collection, and workflow
  type differences.
- `AsyncStream<Void>` or any contentless change notification broadcast to multiple
  independent subscribers. New subscriptions must use typed payloads so subscribers
  can determine relevance without an actor hop. `AsyncChannel` from
  swift-async-algorithms is a competing-consumer rendezvous channel — it is NOT
  suitable for fan-out to multiple independent subscribers.
- ViewModels that import SwiftUI or hold a direct reference to a navigator or routing
  object and call imperative navigation methods on it. ViewModels must express
  navigation intent as output that the View layer consumes, including a typed stream
  or observable state property of a ViewModel-defined enum, a non-isolated closure
  injected by the caller, or a delegate protocol defined by the ViewModel. The View
  layer executes navigation; the ViewModel declares what should happen.
<!-- END project-owned -->

## Project memory

These rules govern every agent invocation in this project. Each
agent's full operating rules (Permission profile, Output policy,
Hard rules) live in its own definition file under
`.claude/agents/<agent>.md`, `.codex/agents/<agent>.toml`, and
`.gemini/agents/<agent>.md`. The agent file is authoritative for
what that agent may and must do; this section carries only the
universal collaboration rules that apply project-wide regardless
of agent role.

- **Trinity rule.** When modifying `CLAUDE.md`, `AGENTS.md`, or
  `GEMINI.md` at the project root, the same change applies to all
  three in the same set of edits. Symmetry is the default;
  asymmetry requires justification as provably tool-specific.
- **No destructive operations without explicit approval.** Before
  any `git rm`, `rm -rf`, file deletion, overwrite, or
  `git reset --hard`, state exactly what will be destroyed and wait
  for explicit approval — even when the overall task is approved.
- **PM chat does not architect.** Architecture, planning,
  implementation, and review work goes to the corresponding agent
  (architect / planner / coder / reviewer / tester / auditor /
  docs-researcher / grpc-schema / repo-ops). The PM chat handles
  BACKLOG, STATUS, CHANGELOG, routing, approvals, and prompt
  construction — not the work the agents do.

<!-- BEGIN project-owned -->
## Phase routing — default agent assignments

### Tool selection: Claude Code CLI vs Xcode Claude Agent

Two agentic tools are available. Choose based on what the task needs:

**Claude Code CLI** — use for all implementation phases via `./agent-run.sh`:
- Reads and writes across the entire codebase in one session
- Runs `./scripts/format.sh`, `./scripts/validate.sh`, `./scripts/test.sh`
- Writes source files as file edits (does NOT commit to git); does not write CHANGELOG.md, BACKLOG.md, STATUS.md, or other root .md files — PM chat handles these
- Follows the full phase prompt workflow
- Run `./agent-run.sh --help` for the full agent list and flag details

**Xcode Claude Agent** (built into Xcode 26.3+) — use selectively:
- Can explore file structure, edit multiple files, run builds and tests, access Apple docs
- **Unique capability**: captures Xcode Previews screenshots to visually verify UI
- Best for: UI-heavy phases (37, 38, 41) where visual Preview verification adds value
- Best for: quick in-editor fixes and one-off questions while reviewing code
- Not suited for: phases requiring script execution, git commits, or CHANGELOG updates

Xcode 26.4 is a refinement release — no changes to agentic coding capabilities from 26.3.

### Agent routing table

All three tools (Claude Code, Codex, Xcode Claude Agent) can execute any phase.
The defaults below identify the better system for each phase. Override
when task characteristics favor a different tool.

| Phase | Default | Agent | Key reason |
|---|---|---|---|
| Architecture / design | **Claude Code** | architect or planner | Multi-file context, extended reasoning |
| Planning / task breakdown | **Claude Code** | planner | Tiebreaker — all systems comparable |
| Dependency evaluation | **Claude Code** | docs-researcher | Web search, nuanced tradeoff analysis |
| Implementation | **Claude Code** | coder | Workspace-write sandbox, scripts, git |
| UI-heavy phases (37, 38, 41) | **Claude Code** or **Xcode Agent** | coder / Xcode Claude Agent | Xcode Agent adds Previews visual verification |
| Code review | **Claude Code** | reviewer | Deep multi-file analysis, Bash diagnostics |
| Testing | **Claude Code** | tester | Pattern generation |
| Debugging | **Claude Code** | coder | Multi-step reasoning, Bash diagnostics |
| Refactoring | **Claude Code** | coder | Mechanical changes in sandbox |
| Documentation | **Claude Code** | docs-researcher | Multi-file context |
| Repo operations | **Claude Code** | repo-ops | Workspace-write sandbox |
| Structural audit | **Claude Code** | auditor | 7-subagent full-codebase audit |

To invoke any Claude Code agent: `./agent-run.sh <cli> --agent <name>` (see `./agent-run.sh --help`).
For Gemini CLI, `agent-run.sh` translates `--agent` to Gemini's native `@agent-name`
syntax transparently — the same command format works for all three CLIs.
To invoke Xcode Agent: open the AI panel in Xcode 26.4 (ensure Claude account is connected)

### Custom agents

Project-specific agents created via Procedure 5 (see
`docs/pack/INSTALL-PROCEDURES.md`). See
`docs/pack/PLATFORM-SKILLS.md` § "Custom agents" for the canonical list
and full skill assignments. All custom agent names begin with `x-`.

| Phase | Agent | Key reason |
|---|---|---|
| (Developer / PM chat adds rows per project during Procedure 5) |  |  |
<!-- END project-owned -->

<!-- BEGIN project-owned -->
## Agent behavior

When acting in this repo:
- Plan first for non-trivial work.
- Call out uncertainty explicitly.
- Do not invent Apple APIs, package capabilities, or build flags.
- Read existing code before introducing new patterns.
- Match local style when it does not violate these rules.
- Prefer changing the smallest correct surface area.
- For high-risk work (concurrency, security, architecture), produce a plan, name verification
  steps, and identify remaining risks before writing code.
<!-- END project-owned -->

## Project addenda

<!-- BEGIN project-owned -->
<!-- Project-original H2 sections from v9.3 land under this heading after
a v9.3 → v10 migration. See docs/pack/INSTALL-PROCEDURES.md Procedure
5-C.2 step 2.b for the migration reconciliation workflow. -->

### Repository overview

This repository is a macOS-only content catalog prototype.
Target: macOS 15+, Xcode 26.4, Swift Package Manager, GitHub (`example-org/SampleApp`).
There is no backend server. All logic runs in-process. The architecture must anticipate a future
first-party gRPC backend with minimal changes: every external integration is behind a protocol,
every concrete implementation is injected, and no domain type ever appears in a transport signature.

### Identity and naming

- Every persistent object in the domain model must carry a **globally unique identifier**
  (use `UUID`; wrap in a typed ID struct — never use raw `UUID` or `String` at domain boundaries).
- Every `Provider`, `Collection`, and `Workflow` instance must also carry a `name` and
  `description` property.

### Abstraction philosophy

The following three abstractions are first-class objects in this app.
Each must be defined as a protocol in the domain layer. Concrete implementations live in the
data layer. No presentation or domain type holds a concrete type directly.

#### DataStore
Represents any persistent store (SwiftData, SQLite, in-memory, remote). All reads and writes
go through the `DataStore` protocol. The current concrete implementation is SwiftData.
**Known limitation**: SwiftData is an object graph store, not a relational database. It is
adequate for a prototype but may require replacement (GRDB/SQLite) when complex queries over
time-series feed data, large event logs, or multi-table joins are needed. Document this
risk in `ARCHITECTURE.md` and ensure the abstraction never leaks SwiftData types into domain
or presentation layers.

#### LogSource / LogEvent / LogSourceGroup
- `LogEvent`: a value type representing a single log entry. Variants: `info`, `warning`,
  `error`, `analytics`. Carries a timestamp, source identifier, and structured payload.
- `LogSource`: a protocol for any logging or analytics sink (console, file, crash reporter,
  analytics service). Implementations are injected; never referenced by concrete type in domain code.
- `LogSourceGroup`: composes an array of `LogSource` instances. When it receives a `LogEvent`,
  it fans it out to every source in the group. Each source handles it independently.
  This is the type that domain and workflow code actually holds — never a bare `LogSource`.

#### FeedService
Provides historical or live content data. Implementations include:
- **Provider-backed**: data stream from a real provider API (Provider Alpha, Provider Beta, Provider Gamma).
- **Third-party provider**: any external content data API.
- **Stub / simulation**: local generated stub for workflow testing (sandbox simulation, unit tests).

A `FeedService` may be pull-based (on-demand fetch) or push-based (streaming). The protocol
must accommodate both. The concrete type in use is selected at injection time — workflows
and the UI never know which implementation they are talking to.

### Domain model — core types

All types below are defined in the domain layer as protocols or base value/reference types.
Concrete provider-specific or transport-specific implementations live in the data layer.

#### Item
- Value type (struct). Subclasses/variants per item kind: Text, Image, Audio, Video.
- All provider-specific item objects must be mapped to the canonical `Item` type at the
  data-layer boundary. Domain and presentation layers only ever see `Item`.
- Carries: content identifier, timestamp, title/summary/body/created/updated/size/status as appropriate.

#### Provider
- Reference type (immutable final class). Data-layer factories (conforming to ProviderFactory)
  construct Provider instances — they do not subclass it. No protocol + base hierarchy exists.
- Each provider owns: one or more `Collection` instances, one or more `FeedService` instances.
- Carries: identifier, name, description, connection status, API credential reference
  (stored in Keychain — never in the model or source).

#### Collection
- Single immutable final class with collectionType: CollectionType discriminator field. Static
  convenience factory methods (Collection.personal, Collection.shared, Collection.archived)
  produce appropriately configured instances. No subclasses exist.
- Carries a **capabilities mask** indicating which item kinds and operation types are
  allowed (text, image, audio, video; batch, streaming).
- Must reference exactly one owning `Provider`.
- Contains: `Entry` array, `Metric` array, `Event` array.

#### Entry
- Subclasses per item kind (TextEntry, ImageEntry, AudioEntry, VideoEntry).

#### Event
- Subclasses per operation type. Represents historical operation records.

#### Operation
- Subclasses per item kind.
- Carries a **capabilities mask** for applicable operation types:
  create/delete, read/write, publish/unpublish,
  import/export, sync/refresh.
- Unavailable operation types for a given item kind or collection type must be represented
  explicitly (not silently omitted) — use a default/unavailable indicator.
- Must reference exactly one `Collection`.

#### Workflow
- Composed (not inherited) with: `Collection`, `LogSourceGroup`, `DataStore`.
- Carries a **capabilities mask** listing required item kinds and operation types.
  The associated collection must satisfy the workflow's required capabilities.
- Accesses `FeedService`, `Entry`, and `Metric` through its `Collection` and `Provider`.

#### WorkflowSchedule
Controls when a workflow runs. Fields and defaults:

| Field | Type | Default |
|---|---|---|
| `isOn` | Bool | `false` |
| `startTime` | Time | day start |
| `stopTime` | Time | day end |
| `startDate` | Date | today |
| `stopDate` | Date | today |
| `daysOfWeek` | [Weekday] | all (Mon–Fri) |

Rules:
- Default `isOn` is always `false`. A workflow does nothing until explicitly enabled.
- **Single-day workflows**: start and stop must be on the same calendar day.
- **Recurring workflows**: start and stop may span different days.
- All operations opened in a run window must be closed at or before the window's stop.
- Must reference exactly one `Collection`.

#### Soft-delete (tombstoning)
Any user-modifiable object (Provider, Collection, Workflow, WorkflowSchedule,
Entry, Operation) must support tombstoning instead of hard deletion.
- A tombstoned object carries a deletion timestamp and is excluded from all active queries.
- Tombstoned objects remain available for logging, reporting, and audit queries.
- No tombstoned object may be selected or used in any active operation.

### Stub and test class tiers

For `Provider`, `Collection`, `FeedService`, `LogSource`, `Workflow`, and any other
major protocol, three implementation tiers must exist:

1. **Stub** (always present): implements the protocol, does the bare minimum to not error.
   Used as a safe default during development before real implementations exist.
2. **Hidden test class** (debug/test builds only, not visible to app users):
   allows automated testing of workflows and components during development.
3. **Visible test class** (available to users in the running app):
   lets users test their workflows safely against simulated data with no real operations.

Use conditional compilation (`#if DEBUG`) to gate hidden test classes.

### Provider API integrations

Stub implementations exist in the Data layer for the architecture phase and serve as the
starting point. Full provider integration is scheduled in the implementation plan:
- **Phase 10** — Provider Alpha (bearer token auth, batch fetch, item publishing)
- **Phase 11** — Provider Beta (OAuth 1.0a, HMAC-SHA1 signing, two-step sync flow)
- **Phase 12** — Provider Gamma (OAuth 2.0 Authorization Code with client_secret Basic Auth, WebSocket streaming, batch sync)

| Provider | API Reference |
|---|---|
| Provider Alpha | https://example.com/alpha/api / https://example.com/alpha/api/docs |
| Provider Beta | https://example.com/beta/home / https://example.com/beta/docs/api/collection/api-collection-v1.html |
| Provider Gamma | https://example.com/gamma / https://example.com/gamma/user-guides/get-started/introduction |

All provider API credentials must be stored in Keychain. Never in UserDefaults, model properties,
or source code.
<!-- END project-owned -->
