# PLATFORM-SKILLS.md — Skill Selection Matrix

This file is the PM chat's authoritative reference for selecting which skills
to load when generating agent prompts. Read this file at prompt-generation time.

---

## How skill selection works

Skill selection in v11 uses **five dimensions plus three orthogonal load
mechanisms**. The dimensions describe project shape; the load mechanisms
describe *why* a skill loads (project-shape implication, agent-role trigger,
or universal applicability). The five dimensions are:

- **D1 — Runtime / OS substrate** (what OS or hardware the code runs on).
- **D2 — Cross-platform languages** (languages not implied by D1, e.g.
  Python).
- **D3 — Component role / app-layer** (client app, server, embedded
  runtime, shared library, CLI tool).
- **D4 — Communication protocols** (gRPC, REST, etc.).
- **D5 — Deployment surface** (App Store distribution, Linux container,
  etc.).

The three orthogonal load mechanisms are:

- **Tier 0 base** — universal-methodology skills that load for every
  project regardless of D1–D5 (e.g. `error-handling`, `documentation`,
  `security-patterns`). Filtered per agent — each agent loads only the
  base skills relevant to its role, but the skill itself is not gated on
  project shape.
- **Dimensional / intersection** — skills loaded by D1–D5 selectors,
  including sparse cells loaded only at intersections (e.g.
  `python-server-architecture` loads only at D2=python ∩ D3=server).
- **Trigger-loaded** — skills loaded because of *who* is invoking them
  (the agent role), not because of project shape (e.g.
  `audit-methodology` loads for every auditor invocation regardless of
  D1–D5).

The PM chat combines all relevant skills when generating a prompt:
*"Load the following skills for this task: {skill-1}, {skill-2}, ..."*.
Skills selected by more than one mechanism load once (deduplicate).

---

## Step 1 — Build the project's skill profile

Walk through the five dimensions and the three load mechanisms below.
Each contributes skills to the project's skill set; the union (after
deduplication) is the full project skill profile.

### Dimension 1 — Runtime / OS substrate

What OS or hardware substrate does this code execute on at runtime?
Select all D1 values where any of the project's code executes at
runtime. A single executable can target multiple D1 values (e.g., a
SwiftUI app shipping on iOS + macOS + watchOS, a Mac Catalyst app
running on iOS + macOS, a cross-platform Rust binary built for Linux
+ macOS + Windows, an Electron app running on macOS + Windows + Linux).
Multiple executables can each target one or more D1 values (e.g., a
monorepo with an iOS app + Python server selects ios + linux-server).
The selection is the union across all of the project's components,
targets, and deployment platforms — be inclusive.

| D1 value | Skills added |
|---|---|
| `ios` | apple-architecture-core, ios-architecture, swift-best-practices, swift-concurrency-patterns, dependency-swift |
| `macos` | apple-architecture-core, macos-architecture, swift-best-practices, swift-concurrency-patterns, dependency-swift |
| `linux-server` | (no D1 skill — Python language skills cover via D2; see also intersections) |

**D1-implied language skills.** Languages bound to a single D1 family
(Swift⇐Apple, C/C++⇐embedded-Python-via-C-API) load via D1 — they are
listed in the rows above and are not separately selected via D2. The
`objc-language` skill loads
under D1 ∈ {ios, macos} *conditional on Objective-C source files being
present in the project*.

**Why `linux-server` exists with no skill.** The `linux-server` row is
present for matrix uniformity — the previous "no platform" elision made
the matrix non-uniform and made D5 selection ambiguous. A
Python-server-on-Linux project selects `linux-server` (no D1 skill),
`python` (D2), `server` (D3), and `linux-container` (D5); the union
loads `python-best-practices`, `dependency-python`,
`python-server-architecture`, `python-data-architecture`,
`deployment-python`.

### Dimension 2 — Cross-platform languages

Which programming languages are present in the codebase that are NOT
already implied by the D1 selection? Languages bound to a single D1
family load via D1 (see Dimension 1 above); D2 carries only languages
that can appear in *any* D1.

| D2 value | Skills added |
|---|---|
| `python` | python-best-practices, dependency-python *(plus python-data-architecture via the intersection table when `python_data_marker_detected()` is true; plus python-server-architecture via the intersection table when D3=server)* |

Select all D2 languages present. Each adds its own skills independently.
The Apple-family languages (Swift, Objective-C, C, C++) are NOT selected
via D2 — they load via D1.

### Dimension 3 — Component role (app-layer)

What architectural role does this component play in the deployed
system? One value per component. Monorepos select multiple values, one
per component. **Functional concerns (auth, search, payments) are NOT
D3** — they belong to custom skills (the `x-` prefix family) and are
declared in the `## Custom skills` section below.

| D3 value | Skills added | Notes |
|---|---|---|
| `client-app` | (none additional) | UI / end-user app; D1 + D2 carry the relevant rules |
| `server` | (intersection-loaded — see §"Intersection table") | Serves requests; intersected with D2 to load language-specific server skills |
| `embedded-runtime` | (none additional) | E.g. embedded Python inside a Swift app — D1 + D2 carry it; no `python-server-architecture` (see intersection table) |
| `shared-library` | (none additional) | Library consumed by other components — D1 + D2 carry it |
| `cli-tool` | (none additional) | Command-line tool; D1 + D2 carry it |

D3 is mostly a *predicate* for intersections, not a skill loader on its
own. The intersection table below carries the actual skill loading for
roles that combine with D2.

### Dimension 4 — Communication protocols

How do components communicate with each other or with external systems?
Multiple values per project are normal.

| D4 value | Skills added |
|---|---|
| `grpc` | grpc-patterns |
| `rest` | rest-patterns |
| `none` | (none) |

Select all protocols in use. A project using both gRPC (internal) and
REST (third-party) selects both values and loads both skills.

### Dimension 5 — Deployment surface

Where and how is this component distributed and operated in production?
Multiple values per project are normal — a monorepo with an Apple app
plus a Linux container backend selects two D5 values.

| D5 value | Skills added |
|---|---|
| `apple-distribution` | deployment-apple |
| `linux-container` | deployment-python *(when D2=python; intersection-loaded — see §"Intersection table")* |

D5 is the deployment-surface axis. It carries `deployment-apple` and
`deployment-python`, making the *distribution / operations* concern
explicit and separate from D1 (runtime substrate) and D3 (app-layer
role).

#### Monorepo D5 scoping note

A monorepo with an Apple app + Linux container backend has D5 =
{`apple-distribution`, `linux-container`} and loads BOTH
`deployment-apple` AND `deployment-python` globally; the loader trusts
the agent prompt (constructed by the PM chat) to scope each *to the
right component* — `deployment-apple` is not relevant to the backend's
containerization, and `deployment-python` is not relevant to the Apple
app's notarization. Agents auditing or modifying a specific component
should confine their reading of the loaded deployment skills to the
component(s) the prompt scopes them to.

### Tier 0 — Base skills (load for every project, every agent)

These skills encode methodology or rules that apply regardless of
D1–D5. They load for every project; the per-agent assignments in
Step 2 below filter which Tier 0 skills each agent actually loads
(e.g. `repo-ops` is only loaded by the `repo-ops` agent — but its
*basis* for loading is Tier 0, not dimensional).

| Skill | Why base |
|---|---|
| api-design | Protocol-agnostic contract design methodology |
| architecture-review | Universal architecture assessment methodology |
| boundary-investigation | Project-side SSOT investigation methodology; flag pack-vs-project boundary violations on every action |
| debugging | Universal root-cause / diagnostics / fix-verification methodology |
| dependency-intake | Universal dependency evaluation methodology |
| documentation | Universal research methodology + drift-detection rules |
| error-handling | Universal error philosophy, retry policy, propagation |
| implementation | Universal code-change workflow, concurrency safety, verification |
| planning | Universal scoping, task breakdown, risk identification, verification strategy |
| repo-ops | Universal git workflows, scripting, command sequencing, safety |
| review | Universal review priorities, examination checklist, finding reporting |
| security-patterns | Universal credential exposure, injection, deserialization, log safety, supply chain |
| testing | Universal test pyramid, design, organization, coverage |
| ui-test-strategy | Universal UI/E2E tool selection, test design, snapshot testing *(loaded only when a UI is present — UI-presence precondition)* |

**14 Tier 0 base skills.** `security-patterns`, `api-design`,
`debugging`, and `ui-test-strategy` are universal-methodology skills and
load as Tier 0.

### Intersection table (sparse cells)

Some skills load only at the intersection of two or more dimensions.
This table is the authoritative source for those sparse cells:

| Skill | Predicate | Source of truth |
|---|---|---|
| `python-server-architecture` | D2=python ∩ D3=server | PM chat reads D2 + D3 selections |
| `python-data-architecture` | D2=python ∩ ((D3=server) ∨ data-marker present) | `scripts/lib/detect.sh::python_data_marker_detected()` is the canonical predicate for the data-marker branch; checks for relevant data / async I/O / ML dependencies in `requirements.txt` / `pyproject.toml` / `setup.py` / `setup.cfg` and for ≥5 `.py` files outside `tests/` |
| `protobuf-patterns` | (any host language) ∩ protobuf-marker present | `scripts/lib/detect.sh::protobuf_marker_detected()` is the canonical predicate; checks for any `.proto` file in the project tree OR dependency manifests listing protobuf tooling (`protobuf`, `swift-protobuf` / `SwiftProtobuf`, `grpc-tools`, `grpc-swift-2`, `protoc`). Loads alongside `grpc-patterns` whenever D4=grpc; loads standalone (without `grpc-patterns`) for non-gRPC protobuf use (binary file format, IPC payloads, Twirp / Connect, persistent storage, log formats) |
| `python-observability-patterns` | D2=python ∩ (D3=server ∨ observability-marker present) | `scripts/lib/detect.sh::python_observability_marker_detected()` is the canonical predicate; checks for OpenTelemetry / Prometheus client / structured-logging dependencies in `requirements.txt` / `pyproject.toml` / `setup.py` / `setup.cfg` / `uv.lock` and for source-file imports of `opentelemetry` / `prometheus_client` / `structlog`. Server projects (D3=server) load unconditionally even without the marker so observability rules apply during new-code review. |
| `apple-swiftdata-patterns` | D1 ∈ {ios, macos} ∩ swiftdata-marker present | `scripts/lib/detect.sh::swiftdata_marker_detected()` is the canonical predicate; checks for any `.swift` file containing `import SwiftData` OR an `@Model` macro attribute, OR a dependency manifest (`Package.swift`, `Package.resolved`, `Podfile`, `Podfile.lock`) listing SwiftData explicitly. SwiftData is first-party Apple (iOS 17+ / macOS 14+) so the manifest marker rarely fires; the source-file markers are primary. Loads alongside `apple-architecture-core` + the per-OS architecture skill |
| `deployment-python` | D2=python ∩ D5=linux-container | PM chat reads D2 + D5 selections |

The PM chat (or a future loader script) walks D1–D5 selectors plus this
intersection table; each skill's predicate is evaluated against the
selected values. Skills loaded by both a dimensional row and an
intersection row load once.

### Trigger-loaded skills (load by agent role, not project shape)

| Skill | Trigger |
|---|---|
| `audit-methodology` | Loaded by `auditor` parent and all 7 `auditor-*` subagents — every audit invocation, regardless of D1–D5 |
| `pm-startup` | Loaded by PM chat at session start (not an agent) |

These are not in any dimension table because no project shape can
suppress them — the agent's role implies them. The `auditor-*`
subagents additionally load Tier 0 + dimensional skills per Step 2; the
trigger here is `audit-methodology` itself.

Pack-repo development additionally uses `verification-harness`,
`implementation-report`, and `commit-discipline` as trigger-loaded
skills. Those skills live in the pack repo's own `.claude/skills/`,
`.codex/skills/`, `.agents/skills/` trees (not under
`project-template/`) and are out of scope for project-side skill
selection. See `docs/pack/PM-CHAT.md` § Pack agent roster for the canonical project-side agent list.

### Combining dimensions and mechanisms — worked examples

Each example walks D1, D2, D3, D4, D5, plus the Tier 0 base / intersection /
trigger contributions. (Tier 0 base loads for every project; per-agent
filtering happens in Step 2 — the examples focus on dimensional / intersection
contributions.)

**iOS Swift app, no server:**
- D1: `ios` → apple-architecture-core, ios-architecture, swift-best-practices, swift-concurrency-patterns, dependency-swift
- D2: (none — Swift implied by D1)
- D3: `client-app` → (none additional)
- D4: `none` → (none)
- D5: `apple-distribution` → deployment-apple
- Intersection: D1 ∈ {ios, macos} ∩ swiftdata-marker (`swiftdata_marker_detected()` → yes when the project's `.swift` sources contain `import SwiftData` or an `@Model` attribute) → apple-swiftdata-patterns
- Tier 0 base: loaded per agent
- **Result (dimensional + intersection, SwiftData present):** apple-architecture-core, ios-architecture, swift-best-practices, swift-concurrency-patterns, dependency-swift, deployment-apple, apple-swiftdata-patterns
- **Result (dimensional + intersection, no SwiftData):** apple-architecture-core, ios-architecture, swift-best-practices, swift-concurrency-patterns, dependency-swift, deployment-apple

**Python gRPC server (Linux container):**
- D1: `linux-server` → (none)
- D2: `python` → python-best-practices, dependency-python
- D3: `server` → (intersection-loaded)
- D4: `grpc` → grpc-patterns
- D5: `linux-container` → (intersection-loaded)
- Intersection: D2=python ∩ D3=server → python-server-architecture; D2=python ∩ data-marker (`python_data_marker_detected()` → yes for any server with relevant data deps) → python-data-architecture; D2=python ∩ (D3=server ∨ observability-marker) (`python_observability_marker_detected()` → yes when OTel / Prometheus client / structured-logging deps or imports are detected; D3=server alone also triggers loading) → python-observability-patterns; protobuf-marker present (`protobuf_marker_detected()` → yes when `.proto` files or protobuf tooling are detected) → protobuf-patterns; D2=python ∩ D5=linux-container → deployment-python
- Tier 0 base: loaded per agent
- **Result (dimensional + intersection):** python-best-practices, dependency-python, grpc-patterns, protobuf-patterns, python-server-architecture, python-data-architecture, python-observability-patterns, deployment-python

**Universal Apple app + Python gRPC server (monorepo):**
- D1: `ios` + `macos` → apple-architecture-core, ios-architecture, macos-architecture, swift-best-practices, swift-concurrency-patterns, dependency-swift; plus `linux-server` for the backend → (none)
- D2: `python` (backend) → python-best-practices, dependency-python
- D3: `client-app` (Apple side) + `server` (backend) → server intersection-loaded
- D4: `grpc` → grpc-patterns
- D5: `apple-distribution` (Apple app) + `linux-container` (backend) → deployment-apple + (deployment-python via intersection); see "Monorepo D5 scoping note" above
- Intersection: D2=python ∩ D3=server → python-server-architecture; D2=python ∩ data-marker → python-data-architecture; D2=python ∩ (D3=server ∨ observability-marker) → python-observability-patterns; protobuf-marker present → protobuf-patterns; D2=python ∩ D5=linux-container → deployment-python
- Tier 0 base: loaded per agent
- **Result (dimensional + intersection):** apple-architecture-core, ios-architecture, macos-architecture, swift-best-practices, swift-concurrency-patterns, dependency-swift, python-best-practices, dependency-python, grpc-patterns, protobuf-patterns, python-server-architecture, python-data-architecture, python-observability-patterns, deployment-apple, deployment-python

**macOS Swift app with embedded Python:**
- D1: `macos` → apple-architecture-core, macos-architecture, swift-best-practices, swift-concurrency-patterns, dependency-swift
- D2: `python` (embedded) → python-best-practices, dependency-python
- D3: `client-app` (Swift host) + `embedded-runtime` (Python) → no `python-server-architecture` (embedded Python is not a server)
- D4: `none` → (none)
- D5: `apple-distribution` → deployment-apple
- Intersection: D2=python ∩ data-marker (load only when `python_data_marker_detected()` returns yes for the embedded Python codebase, e.g. ≥5 `.py` files or relevant dependencies) → python-data-architecture; the C-API bridge between Swift and embedded Python additionally loads c-language
- Tier 0 base: loaded per agent
- **Result (dimensional + intersection):** apple-architecture-core, macos-architecture, swift-best-practices, swift-concurrency-patterns, dependency-swift, python-best-practices, dependency-python, deployment-apple, python-data-architecture, c-language

**macOS Swift app with C++ performance code:**
- D1: `macos` → apple-architecture-core, macos-architecture, swift-best-practices, swift-concurrency-patterns, dependency-swift; the C++ performance code loads cpp-language as a D1-implied auxiliary (Swift / C++ interop on Apple)
- D2: (none)
- D3: `client-app` → (none additional)
- D4: `none` → (none)
- D5: `apple-distribution` → deployment-apple
- Intersection: (none)
- Tier 0 base: loaded per agent
- **Result (dimensional + intersection):** apple-architecture-core, macos-architecture, swift-best-practices, swift-concurrency-patterns, dependency-swift, cpp-language, deployment-apple

---

## Step 2 — Select skills per agent

For each agent prompt, load the agent's Tier 0 base skills plus the
dimensional / intersection skills from Step 1 that are relevant to that
agent's work. Not every agent needs every dimensional skill — load only
what the agent's role requires.

### Agents and their skill assignments

**architect**
- Tier 0 base: architecture-review, api-design, planning, documentation, error-handling, security-patterns
- Dimensional (filtered by D1/D2/D3/D4/D5): apple-architecture-core, ios-architecture, macos-architecture, swift-best-practices, swift-concurrency-patterns *(D1-implied for D1 ∈ {ios, macos} — concurrency design is an architectural concern at the actor / state-isolation boundary)*, python-best-practices, python-server-architecture, python-data-architecture, grpc-patterns, protobuf-patterns, rest-patterns, c-language, objc-language, cpp-language, apple-swiftdata-patterns *(load when `swiftdata_marker_detected()` is true — schema design and storage boundaries are an architectural concern)*, python-observability-patterns *(load when `python_observability_marker_detected()` is true OR D3=server)*

**coder**
- Tier 0 base: implementation, debugging, error-handling, documentation
- Dimensional (filtered): swift-best-practices, swift-concurrency-patterns *(D1-implied for D1 ∈ {ios, macos})*, python-best-practices, grpc-patterns, protobuf-patterns, rest-patterns, c-language, objc-language, cpp-language, apple-swiftdata-patterns *(load when `swiftdata_marker_detected()` is true)*, python-observability-patterns *(load when `python_observability_marker_detected()` is true OR D3=server)*

**reviewer**
- Tier 0 base: review, error-handling, security-patterns, api-design, debugging
- Dimensional (filtered): swift-best-practices, swift-concurrency-patterns *(D1-implied for D1 ∈ {ios, macos})*, python-best-practices, python-server-architecture, python-data-architecture, grpc-patterns, protobuf-patterns, rest-patterns, apple-architecture-core, ios-architecture, macos-architecture, c-language, objc-language, cpp-language, apple-swiftdata-patterns *(load when `swiftdata_marker_detected()` is true)*, python-observability-patterns *(load when `python_observability_marker_detected()` is true OR D3=server)*

**tester**
- Tier 0 base: testing, ui-test-strategy *(when UI present)*
- Dimensional (filtered): swift-best-practices, python-best-practices, grpc-patterns, rest-patterns, ios-architecture, macos-architecture, c-language, objc-language, cpp-language *(language skills for framework / naming conventions and test double patterns; protocol skills for transport-level test harnesses; platform architecture skills for UI test surface knowledge)*

**planner**
- Tier 0 base: planning, architecture-review

**repo-ops**
- Tier 0 base: repo-ops

**docs-researcher**
- Tier 0 base: documentation, dependency-intake
- Dimensional (filtered): deployment-apple, deployment-python, python-observability-patterns, dependency-swift, dependency-python

**grpc-schema**
- Tier 0 base: api-design
- Dimensional: grpc-patterns, protobuf-patterns

**auditor** (parent)
- Trigger: audit-methodology
- The parent auditor only loads `audit-methodology`. Subagents load
  their own dimensional / Tier 0 skills in their isolated contexts. The
  PM chat passes the per-subagent skill list in the parent's invocation
  prompt for the parent to relay to each subagent at spawn time.

**auditor-architecture**
- Trigger: audit-methodology
- Dimensional (filtered): apple-architecture-core, ios-architecture, macos-architecture, swift-concurrency-patterns *(D1-implied for D1 ∈ {ios, macos} — actor isolation, Sendable boundaries, and GCD ↔ async-await interop are architectural concerns at the concurrency boundary)*, python-server-architecture, python-data-architecture, protobuf-patterns *(load when `protobuf_marker_detected()` is true — schema design is an architectural concern at the transport boundary)*, apple-swiftdata-patterns *(load when `swiftdata_marker_detected()` is true — `@Model` schema design and storage-layer threading are architectural concerns at the persistence boundary)*, python-observability-patterns *(load when `python_observability_marker_detected()` is true OR D3=server — provides the structural observability rules: SDK init wiring, span lifecycle, exporter / collector tier placement, redaction-pipeline shape, sampling architecture)*
- Platform filtering: load only the architecture skills that match the project's D1/D2/D3 selectors. A pure Python server loads `python-server-architecture` + `python-data-architecture` + `python-observability-patterns`. A pure iOS app loads `apple-architecture-core` + `ios-architecture` only. Substantive observability infrastructure rules for D2=python projects live in `python-observability-patterns` (loaded alongside `python-server-architecture` whenever D3=server, or per `python_observability_marker_detected()` for non-server Python processes that emit telemetry); for non-Python projects observability infrastructure rules live inside the platform architecture skills. For non-server multi-file Python projects, load `python-data-architecture` only (per the intersection-table predicate via `python_data_marker_detected()`); do NOT load `python-server-architecture` because the server-specific rules do not apply.

**auditor-code**
- Trigger: audit-methodology
- Tier 0 base: error-handling, security-patterns
- Dimensional (filtered): swift-best-practices, swift-concurrency-patterns *(D1-implied for D1 ∈ {ios, macos} — provides actor-isolation correctness rules, Sendable-conformance audits, do-not-mix anti-patterns flagged at code-review level, e.g., `semaphore.wait()` from a Swift Concurrency context, GCD calls from inside an `actor`, captured mutable references in `@Sendable` closures)*, python-best-practices, c-language, objc-language, cpp-language; plus python-data-architecture (load per the intersection-table predicate via `python_data_marker_detected()` — provides performance anti-pattern rules like N+1 query detection, repository pattern correctness, Pydantic placement, ML isolation); plus python-server-architecture (load only when D3=server — provides server-specific rules: servicers, grpc.aio handlers, interceptors, background tasks); plus protobuf-patterns (load per `protobuf_marker_detected()` — provides field-evolution / wire-compatibility rules that auditor-code uses to flag risky `.proto` changes and hand-edited generated code); plus apple-swiftdata-patterns (load per `swiftdata_marker_detected()` — provides `@Model` performance anti-pattern rules like N+1 relationship traversal, missing `relationshipKeyPathsForPrefetching`, unbounded `FetchDescriptor` results, and `ModelContext` threading violations); plus python-observability-patterns (load per the intersection-table predicate via `python_observability_marker_detected()` OR when D3=server — provides metric / span / log code idiom rules: do-not-use-Summary in distributed deployments, label cardinality, span lifecycle anti-patterns, structured-log required fields, redaction-pipeline shape).
- The `error-handling` skill provides the cross-cutting error-handling rules (boundary mapping, retry policy uniformity) that this subagent audits at the systemic level. The `security-patterns` skill provides the log-safety, injection, and deserialization rules that overlap with code-level audit findings (added per architecture §5.9). The language skills (`swift-best-practices`, `python-best-practices`) supply the dead-code and unused-import detection rules.

**auditor-tests**
- Trigger: audit-methodology
- Tier 0 base: testing, ui-test-strategy
- Dimensional (filtered): swift-best-practices, python-best-practices *(language skills for test naming conventions and test framework idioms)*
- Skip `ui-test-strategy` for server-only projects (UI-presence precondition).

**auditor-docs**
- Trigger: audit-methodology
- Tier 0 base: documentation
- No dimensional skills — drift detection is language-agnostic. The `documentation` skill includes the drift-detection rules section that this subagent uses.

**auditor-security**
- Trigger: audit-methodology
- Tier 0 base: security-patterns
- Dimensional (filtered): dependency-swift, dependency-python
- The `security-patterns` skill includes the supply-chain section (CVEs, license compatibility, abandoned packages) that this subagent owns per `audit-methodology` rules 33–34.

**auditor-ui** (skipped for server-only projects)
- Trigger: audit-methodology
- Dimensional (filtered): apple-architecture-core, ios-architecture, macos-architecture, swift-best-practices *(for view code idioms)*
- Platform filtering: only loaded for projects with a UI layer (UI-presence precondition). The platform architecture skills supply the accessibility, view-thickness, and UI-state rules — no separate accessibility skill.

**auditor-ops** (always runs)
- Trigger: audit-methodology
- Dimensional (filtered by D5): deployment-apple, deployment-python, python-observability-patterns
- Always loaded for every audit because every project deploys somewhere. The deployment + observability skills cover the platform-specific deployment configuration rules and observability *configuration* (vs. observability *infrastructure*, which lives in `python-observability-patterns` for D2=python projects and in the platform architecture skills for non-Python projects).

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
located in `.claude/skills/`, `.codex/skills/`, or `.agents/skills/` depending
on which tool runs the agent.

---

## Full skill inventory

### Tier 0 base skills (14)

Universal-methodology skills loaded for every project regardless of D1–D5;
the per-agent assignments in Step 2 filter which Tier 0 skills each agent
actually loads.

| Skill | Description | Primary agents |
|---|---|---|
| api-design | API design philosophy, versioning, error design, protocol selection | architect, grpc-schema, reviewer |
| architecture-review | Platform-agnostic architecture assessment methodology | architect, planner, reviewer, auditor-architecture |
| boundary-investigation | Project-side SSOT investigation methodology; flag pack-vs-project boundary violations on every action | architect, coder, planner, reviewer, docs-researcher |
| debugging | Root cause methodology, diagnostics, fix verification | coder, reviewer |
| dependency-intake | Platform-agnostic dependency evaluation methodology | docs-researcher, auditor-security |
| documentation | Platform-agnostic research methodology, drift detection (for audits) | docs-researcher, auditor-docs |
| error-handling | Universal domain error philosophy, retry policy, propagation | coder, reviewer, auditor-code |
| implementation | Code change workflow, concurrency safety, verification | coder |
| planning | Scoping, task breakdown, risk identification, verification strategy | planner, architect |
| repo-ops | Git workflows, scripting, command sequencing, safety | repo-ops |
| review | Review priorities, examination checklist, finding reporting | reviewer |
| security-patterns | Credential exposure, injection, deserialization, log safety, supply chain (CVEs, licenses) | reviewer, auditor-security, auditor-code |
| testing | Test pyramid, design, organization, coverage | tester, auditor-tests |
| ui-test-strategy | UI/E2E tool selection, test design, snapshot testing *(loaded only when a UI is present)* | tester, auditor-tests, auditor-ui |

### Dimensional skills (20)

Skills loaded by D1–D5 selectors. Each skill's "Cell" column identifies
which dimension(s) load it.

| Skill | Cell | Description | Agents |
|---|---|---|---|
| apple-architecture-core | D1 ∈ {ios, macos} | Cross-platform Apple patterns, SwiftUI-first, layer discipline | architect, reviewer, auditor-architecture, auditor-ui |
| ios-architecture | D1=ios | iOS / iPadOS scene lifecycle, UIKit interop, App Store boundaries, accessibility, observability infrastructure | architect, reviewer, tester, auditor-architecture, auditor-ui |
| macos-architecture | D1=macos | macOS NSDocument, windows, menu bar, AppKit, sandbox, accessibility, observability infrastructure | architect, reviewer, tester, auditor-architecture, auditor-ui |
| swift-best-practices | D1 ∈ {ios, macos} *(D1-implied)* | Swift type system, immutability, error handling, testing tooling, style, dead code *(concurrency-design rules live in `swift-concurrency-patterns`)* | architect, coder, reviewer, auditor-code, auditor-ui |
| swift-concurrency-patterns | D1 ∈ {ios, macos} *(D1-implied)* | Modern Swift Concurrency (async/await, structured concurrency, actor isolation, Sendable, `@preconcurrency`, AsyncSequence / AsyncStream, Swift 6 strict checking, continuation bridging) and Grand Central Dispatch (DispatchQueue selection, DispatchGroup, DispatchSemaphore caveats, barrier writes, QoS, DispatchSource, GCD ↔ async-await modernization, do-not-mix anti-patterns) | architect, coder, reviewer, auditor-architecture, auditor-code |
| objc-language | D1 ∈ {ios, macos} *(D1-implied, conditional on ObjC sources)* | Objective-C ARC, nullability, bridging, legacy code patterns | coder, reviewer, auditor-code |
| c-language | D1=embedded-mcu *(D1-implied)* OR (D2=python ∩ embedded-Python via C API) | C memory ownership, pointers, buffers, const, Swift/Python interop | architect, coder, reviewer, auditor-code |
| cpp-language | D1=embedded-mcu *(D1-implied, conditional)* OR Apple project with C++ performance code | C++ RAII, smart pointers, Swift-C++ interop, rule of five | coder, reviewer, auditor-code |
| python-best-practices | D2=python | Python type hints, async, error handling, ruff/pyright, style, dead code | architect, coder, reviewer, auditor-code |
| dependency-python | D2=python | PyPI evaluation, wheels, version pinning, type stubs, security | docs-researcher, auditor-security |
| dependency-swift | D1 ∈ {ios, macos} | SPM evaluation, Apple framework alternatives, binary frameworks | docs-researcher, auditor-security |
| grpc-patterns | D4=grpc | gRPC service patterns: servicers, interceptors, streaming, deadlines, error model, async handlers, grpc-swift-2 / grpc.aio specifics, gRPC-side cross-language conventions *(Proto3 schema rules live in `protobuf-patterns`; load both when D4=grpc)* | architect, grpc-schema, coder, reviewer |
| protobuf-patterns | (any host language) ∩ protobuf-marker *(intersection — see `scripts/lib/detect.sh::protobuf_marker_detected()`)* | Proto3 schema-design rules: field numbering invariants, backward / forward compatibility, well-known types, `oneof` semantics, code-generation options, package conventions, `buf` tooling. Standalone-usable (loads without `grpc-patterns` for non-gRPC protobuf consumers) | architect, grpc-schema, coder, reviewer, auditor-architecture, auditor-code |
| rest-patterns | D4=rest | REST/HTTP URL design, HTTP methods, status codes, OpenAPI, caching | architect, coder, reviewer |
| deployment-apple | D5=apple-distribution | Code signing, entitlements, notarization, privacy manifests, observability config | auditor-ops, docs-researcher |
| deployment-python | D5=linux-container ∩ D2=python *(intersection)* | Docker, secrets, health checks, graceful shutdown, production config, observability config | auditor-ops, docs-researcher |
| python-server-architecture | D2=python ∩ D3=server *(intersection)* | Python server structure: gRPC servicers / FastAPI handlers, grpc.aio, async handler I/O, server interceptors / middleware, background-task patterns, observability infrastructure | architect, reviewer, auditor-architecture, auditor-code |
| python-observability-patterns | D2=python ∩ (D3=server ∨ observability-marker) *(intersection — see `scripts/lib/detect.sh::python_observability_marker_detected()`)* | OpenTelemetry tracing setup, span lifecycle, trace context propagation, auto-instrumentation, exporter configuration; Prometheus metrics naming / cardinality / type selection / multiprocess exposition; structured logging field requirements + trace-log correlation; head sampling; SLO definition shape; retention-policy shape | architect, coder, reviewer, auditor-architecture, auditor-code, auditor-ops, docs-researcher |
| python-data-architecture | D2=python ∩ data-marker *(intersection — see `scripts/lib/detect.sh::python_data_marker_detected()`)* | Python data and I/O architecture: repository pattern, N+1 prevention, Pydantic placement at I/O boundaries, ML inference isolation, no-direct-driver | architect, reviewer, auditor-architecture, auditor-code |
| apple-swiftdata-patterns | D1 ∈ {ios, macos} ∩ swiftdata-marker *(intersection — see `scripts/lib/detect.sh::swiftdata_marker_detected()`)* | SwiftData object-store rules: `@Model` macro design, `ModelContainer` / `ModelContext` lifecycle and threading, `FetchDescriptor` construction, relationship-traversal performance, schema migration, history tracking, CloudKit sync, `save()` semantics | architect, coder, reviewer, auditor-architecture, auditor-code |

**20 dimensional / intersection skills.** The Cell column is the
authoritative load predicate; six rows
(`python-server-architecture`, `python-observability-patterns`,
`python-data-architecture`, `protobuf-patterns`,
`apple-swiftdata-patterns`, `deployment-python`)
are intersection-loaded per the §"Intersection table" predicates;
the remaining 14 load directly from a single D1/D2/D4/D5 selector
(D1-implied rows include `swift-best-practices` and
`swift-concurrency-patterns`).

### Trigger-loaded skills (1)

| Skill | Description | Trigger |
|---|---|---|
| audit-methodology | Audit report format, severity scale, subagent coordination, file scopes, ownership precedence | `auditor` parent + all 7 subagents |

### PM chat operational skill (2)

These skills are outside the dimension model and the trigger model. They
are not loaded by any agent — they are used exclusively by the PM chat
itself (and, for `pm-help`, as a quick command reference for any tool's
user) for session startup, orientation, and pack-command lookup. They
exist in the skill directory because the template's skill loading
mechanism is uniform across tools, but their purpose is PM chat
operational, not agent role guidance.

| Skill | Description | Loaded by |
|---|---|---|
| pm-startup | PM chat session startup procedure: read state files, check TD-TBD sentinels, report ready status | PM chat only (not an agent) |
| pm-help | Show all project commands and colloquial mappings (the `/pm-help` quick reference) | PM chat / any tool user (not an agent) |

**Total skills: 37** (14 Tier 0 base + 20 dimensional / intersection + 1 trigger-loaded + 2 PM chat operational).

---

## Custom agents

Project-specific agents created via Procedure 5 (INSTALL-PROCEDURES.md).
All entries in this section begin with `x-`, the reserved prefix for
project-added files in pack-controlled directories (see
INSTALL-PROCEDURES.md § "Project file conventions in pack-controlled
directories"). The PM chat treats these as equivalent to pack agents
for skill loading and routing, with the single difference that they
are project-owned and preserved across pack upgrades.

| Agent | Purpose | Dimension | Phase routed to | Base skills | Dimensional skills | Read/write mode |
|---|---|---|---|---|---|---|
| `x-deployer` | Release packaging and staging deploy | Component Roles | Repo operations | repo-ops | deployment-apple, deployment-python | write |

*This row is illustrative. The PM chat replaces it with real entries during
Procedure 5 (see INSTALL-PROCEDURES.md). If a project has no custom agents, the section body is
`*No custom agents defined for this project.*`.*

---

## Custom skills

Project-specific skills created via Procedure 5 (INSTALL-PROCEDURES.md).
All entries in this section begin with `x-`, the reserved prefix for
project-added files in pack-controlled directories (see
INSTALL-PROCEDURES.md § "Project file conventions in pack-controlled
directories"). Loaded by agents via the same instruction block as pack
skills — see "Step 3 — Generate the prompt" above.

| Skill | Description | Dimension | Loaded by |
|---|---|---|---|
| `x-brokerage-api` | OT broker-adapter patterns, capability masks, idempotency | Communication Protocols | reviewer, auditor-code, x-deployer |

*This row is illustrative. The PM chat replaces it with real entries during
Procedure 5 (see INSTALL-PROCEDURES.md). If a project has no custom skills, the section body is
`*No custom skills defined for this project.*`.*

---

## Extending this file

To add support for a new platform, language, role, protocol, or deployment
surface: create the required skill files, then add rows to the appropriate
dimension tables above (D1–D5), the Tier 0 base table, the intersection
table, or the trigger-loaded table — whichever applies. See the dimension
extension rules in the pack's design documentation for the framing rules
that govern each dimension and the governance checklist for new skills.

### Naming convention for new skills

The skill catalog uses four suffixes, each tied to a different kind of
content. **New skills must follow this convention.** Existing skills are
not renamed — the cost of breaking external references
outweighs the consistency benefit.

- **`*-best-practices`** — languages with idiomatic-style rules
  (formatting, dead-code policy, type-system idioms, error-handling
  idioms, testing tooling). Examples: `swift-best-practices`,
  `python-best-practices`.
- **`*-language`** — languages where ownership / memory / interop
  dominate the rule set rather than idiomatic style. Examples:
  `c-language`, `cpp-language`, `objc-language`.
- **`*-architecture`** — platform-specific structural rules: layer
  discipline, lifecycle, navigation, persistence boundaries, server
  structure, observability infrastructure. Examples:
  `apple-architecture-core`, `ios-architecture`, `macos-architecture`,
  `python-server-architecture`, `python-data-architecture`.
- **`*-patterns`** — cross-cutting concerns and recurring design rules
  not bound to a single platform or language. Examples:
  `grpc-patterns`, `rest-patterns`, `security-patterns`, plus
  `protobuf-patterns` (Proto3 schema design standalone of gRPC),
  `apple-swiftdata-patterns` (SwiftData object-store rules), and
  `swift-concurrency-patterns` (modern Swift Concurrency + GCD).

When the suffix is genuinely ambiguous (e.g., a new skill could plausibly
be `*-best-practices` or `*-architecture`), choose the suffix that
matches the dominant content of the SKILL.md, and record the rationale
in the BACKLOG entry that creates the skill.

> **Maintainability rule.** Adding a new skill is a mechanical edit when
> it fits the existing dimensions, patterns, and naming conventions
> documented above. See the pack-repo trinity (`CLAUDE.md` / `AGENTS.md`
> / `GEMINI.md` `## Pack memory`) for the full mechanical-vs-structural
> threshold and the client `x-` preservation rule.
