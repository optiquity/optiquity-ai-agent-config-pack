# V9-DESIGN.md — AI Agent Config Pack v9 Design Document

*Created: April 2026*
*Status: Planning — no implementation has begun*
*Purpose: Authoritative design reference for all v9 work. Any PM chat session
on any tool should read this file before beginning any v9 implementation step.
Do not modify this file without explicit approval — it is the design record.*

---

## How to use this document

This document is the "why" and "what" of v9 — not the "how." It does not contain
implementation instructions, file contents, or pseudocode. Those belong in agent
prompts generated at implementation time by the PM chat.

**Part 1** — Why v9 exists: the problem statement.
**Part 2** — Settled design decisions with rationale and rejected alternatives.
  Decisions 1–8 are written here. Decision 9 (unified template structural
  specification) is added as part of Step 3 implementation.
**Part 3** — PM chat architecture: how the PM chat works across all three major tools.
**Part 4** — New, changed, and removed documentation.
**Part 5** — Backlog map: every BD item and its v9 disposition.
**Part 6** — Implementation sequence: ordered steps with problem, goal, success,
  dependencies, and BD cross-references.

Tool capability reference lives in `maintenance-docs/TOOL-COMPARISON.md`.
That document is versioned separately and updated as tools evolve.

---

## Part 1 — Why v9 Exists

### The problem

The pack currently ships three template directories: `apple-app-template`,
`python-server-template`, and `apple-app-plus-python-server-template`. Each
contains a near-identical set of agent files, skills, scripts, and config files
with platform-specific differences. Every time a new platform is needed, the
entire structure must be duplicated.

The clearest illustration: adding Android support under the current model
requires creating a fourth template directory with ~25 duplicated files, a new
`android-architect` agent, and a new template entry in every piece of
documentation that references template structure. Adding Windows, embedded C,
or a C++ server would each require the same. This is unsustainable — the
maintenance burden grows linearly with every new platform.

At the same time, the three major AI coding tools (Claude, Codex, Gemini) have
converged on a shared skills standard. A skill written for one runs on the
others. The pack's multi-template architecture predates this convergence and
does not take advantage of it.

### What v9 changes

v9 replaces the multi-template architecture with a single unified template and
a composable skill library. Adding a new platform requires writing skill files
— not duplicating template directories. Agents become platform-agnostic; their
platform knowledge comes from skills selected at prompt-generation time by the
PM chat.

v9 also brings the pack's tool coverage to parity: Claude, Codex, and Gemini
are all supported as first-class tools, with documented PM chat architecture
for each and optimized agent/skill files for each tool's native format.

---

## Part 2 — Design Decisions and Rationale

### Decision 1 — Single unified template replaces three template directories

**Decision:** The three template directories are collapsed into one. A new
project is started from a single template. Platform-specific behavior is
determined by which skills the PM chat loads for that project, not by which
template directory was copied.

**Rationale:** The directories are structurally identical except for CLAUDE.md,
AGENTS.md (Codex context file), and a few agent files. The real platform specialization flows through
ARCHITECTURE.md and CLAUDE.md (project-specific), not through the template
agent files (which are generic roles). Moving platform knowledge to skills
makes this explicit and makes the template maintainable.

**Alternatives rejected:**
- *Keep three directories, add a fourth for Android:* Rejected because every new
  platform adds ~25 files. Five platforms means 125 files of near-identical
  content. Unsustainable.
- *Generator script that assembles a template from components:* Considered but
  rejected because it adds tooling complexity and a build step. Skills achieve
  the same composability without any generator.

---

### Decision 2 — Agent generalization: one architect, one of everything

**Decision:** `apple-architect` and `python-architect` are merged into a single
`architect` agent with a platform-agnostic system prompt. All other existing
agents (coder, reviewer, tester, docs-researcher, planner, repo-ops, grpc-schema)
are already platform-agnostic and remain unchanged. No new agents are created
for new platforms — new platforms add skills, not agents.

The `auditor` agent is new in v9 and is not in this list because it does not
exist in v8.9. It is defined in Decision 6.

**Rationale:** The two architect agents differ only in which platform rules they
know. That knowledge moves to skills. A single architect agent that reads
platform skills is equivalent to a specialized agent — the knowledge is
identical, only the delivery mechanism differs.

**Alternatives rejected:**
- *Keep separate architect agents, add platform skills:* Rejected because it
  maintains two agents doing the same job, requiring both to be updated whenever
  the architect role changes.
- *One agent per platform per role (ios-coder, macos-coder, etc.):* Rejected
  explicitly — this is the proliferation problem in its worst form.

**Exception:** `grpc-schema` may remain as a specialized agent or become a skill.
Its scope is narrow enough for either. Decision made in Step 3 (template
structure design) and implemented in Step 7.

---

### Decision 3 — Skill taxonomy: shared skills, composable by project type

**Decision:** Platform knowledge lives in skill files under `.claude/skills/`,
`.codex/skills/`, and `.gemini/skills/`. Skills are composable — the PM chat
selects the combination appropriate for the project type. Skills may be shared
across multiple agents or dedicated to one.

The v9 skill library has two tiers: existing v8.9 role-based skills that are
carried forward unchanged, and new platform-knowledge skills that are additive.
The combination provides both agent workflow guidance (role skills) and platform
context (platform skills).

**Tier 1 — Existing v8.9 role-based skills (carried forward unchanged):**

These skills are already platform-agnostic and cross-tool compatible. They teach
agents how to perform their roles regardless of platform. No restructuring needed.

| Skill | Covers | Primary agent(s) |
|---|---|---|
| `architecture-review` | Assessing architecture, module boundaries, concurrency, interop | architect |
| `debugging` | Tracing failing paths, reproducing bugs, narrowing causes | coder |
| `dependency-intake` | Evaluating third-party packages before adoption | docs-researcher |
| `documentation` | Verifying APIs, config, version features from official docs | docs-researcher |
| `error-handling` | Domain error types, gRPC status mapping, retry logic, propagation | coder, reviewer |
| `implementation` | Adding code, fixing bugs, targeted refactors | coder |
| `planning` | Scoping work, sequencing implementation, defining verification | planner |
| `repo-ops` | Repo operations, scripted edits, Git-safe workflows | repo-ops |
| `review` | Reviewing correctness, regressions, concurrency, architecture drift | reviewer |
| `testing` | Designing unit, integration, UI, and end-to-end tests | tester |
| `ui-test-strategy` | Choosing between XCTest, Swift Testing, XCUITest, Maestro | tester |
| `api-design` | gRPC service contracts, HTTP API design, validation, versioning | architect, grpc-schema |
| `python-architecture` | Python server architecture, grpc.aio handlers, repository pattern | architect |
| `grpc-schema` | Proto3 schema design, buf validation, gRPC service contract review³ | architect, grpc-schema |

*Note: `api-design` and `python-architecture` currently exist only in the
combined apple+python template. In v9, all role skills exist in the unified
template regardless of project type — the PM chat loads only those relevant
to the active task.*

*³ The v8.9 `grpc-schema` role skill is replaced by the v9 `grpc-patterns`
Tier 2 platform skill. The Tier 2 skill carries the same content with expanded
platform guidance. The Tier 1 `grpc-schema` skill is not carried forward — it
is superseded. See Tier 2 footnote 2.*

**Tier 2 — New v9 platform-knowledge skills (additive):**

These skills encode platform-specific rules, patterns, and constraints. They
are loaded by the PM chat based on project type and injected into agent prompts.

| Skill | Covers | Shared / Dedicated |
|---|---|---|
| `swift-best-practices` | Swift language, concurrency, type system, Swift 6 | Shared: architect, coder, reviewer, auditor |
| `apple-architecture-core` | Patterns shared across all Apple platforms | Shared: architect, reviewer, auditor |
| `ios-architecture` | iOS/iPadOS-specific: scene lifecycle, App Store boundaries¹ | Shared: architect, reviewer, auditor |
| `macos-architecture` | macOS-specific: NSDocument, menu bar, AppKit, sandbox | Shared: architect, reviewer, auditor |
| `python-best-practices` | Python patterns, async, type hints, ruff/pyright | Shared: architect, coder, reviewer, auditor |
| `grpc-patterns` | Protobuf schema design, gRPC service patterns, buf² | Shared: architect, grpc-schema, coder, reviewer |
| `c-language` | Memory ownership, pointer safety, Swift/Python interop | Shared: architect, coder, reviewer, auditor |
| `objc-language` | ARC, nullability, bridging headers, legacy patterns | Shared: coder, reviewer, auditor |
| `cpp-language` | RAII, smart pointers, Swift-C++ interop, rule of five | Shared: coder, reviewer, auditor |
| `audit-methodology` | Audit report format, severity scale, subagent coordination model | Dedicated: auditor parent + subagents |
| `deployment-apple` | Signing, entitlements, notarization, privacy manifest | Shared: auditor, docs-researcher |
| `deployment-python` | Docker, secrets management, health checks | Shared: auditor, docs-researcher |
| `security-patterns` | Credential exposure, injection, unsafe deserialization | Shared: auditor, reviewer |

*¹ The v9 `ios-architecture` platform skill replaces and extends the v8.9
`ios-architecture` role skill. The new skill merges both purposes: platform
knowledge (scene lifecycle, App Store boundaries) and architectural assessment
guidance (SwiftUI/UIKit interop decisions, module boundaries). The name is
preserved to minimize migration disruption.*

*² The v9 `grpc-patterns` platform skill replaces the v8.9 `grpc-schema` role
skill. The name changes to avoid collision with the `grpc-schema` agent name
and to better reflect its content (patterns, not just schema).*

**Skill selection by project type (PM chat reference):**

| Project type | Platform skills to load | Role skills always available |
|---|---|---|
| macOS Swift app | swift-best-practices, apple-architecture-core, macos-architecture | All Tier 1 skills |
| iOS Swift app | swift-best-practices, apple-architecture-core, ios-architecture | All Tier 1 skills |
| Universal iOS+macOS | swift-best-practices, apple-architecture-core, ios-architecture, macos-architecture | All Tier 1 skills |
| Python gRPC server | python-best-practices, grpc-patterns | All Tier 1 skills |
| Swift + embedded Python | swift-best-practices, macos-architecture, c-language | All Tier 1 skills |
| Mixed-language Apple | add objc-language or cpp-language as needed | All Tier 1 skills |
| Future: Android | android-architecture, kotlin-best-practices (new skills, no new agents) | All Tier 1 skills |

*Note on Tier 1 availability: All Tier 1 role skills exist in the unified
template's skill directories and are technically available to any project. The
PM chat loads only those relevant to the active task — for example,
`python-architecture` and `api-design` are not loaded for a Swift-only
architect pass, and `ui-test-strategy` is not loaded for a Python server project.*

**Rationale:** Skills are the correct unit of platform knowledge because they
are composable, independently maintainable, and cross-tool compatible. The
two-tier structure preserves all working v8.9 behavior (role skills) while
adding platform composability (platform skills). The shared/dedicated boundary
is determined by whether the skill's content is equally useful to multiple
agents without modification.

**Alternatives rejected:**
- *Encode platform knowledge in CLAUDE.md per project:* Rejected because it
  duplicates content across every project repo and cannot be updated centrally.
- *Separate skill files per agent per platform:* Rejected — combinatorial explosion.
- *Replace role skills with platform skills entirely:* Rejected — role skills
  teach agents how to do their jobs; platform skills teach agents what the
  platform requires. Both are needed.

**Note on skill distribution:** skills.sh (Vercel's cross-platform skill package
manager, `npx skills add`) is becoming the standard install method for agent
skills across Claude Code, Codex, and Gemini CLI. Publishing pack skills there
would enable one-command installation for new projects. This is tracked as BD-031
(deferred) — skills must be stable before publication makes sense.

---

### Decision 4 — Script restructuring: language-specific scripts with wrapper

**Decision:** Replace monolithic `format.sh` and `validate.sh` per template
with language-specific scripts (`format-swift.sh`, `format-python.sh`,
`validate-swift.sh`, `validate-python.sh`, `validate-proto.sh`) plus thin
wrapper scripts (`format.sh`, `validate.sh`) that call the appropriate
language-specific scripts based on what the project contains. Extend the same
approach to `bootstrap.sh` (→ `bootstrap-swift.sh`, `bootstrap-python.sh`
called by a wrapper) and `agent-post-edit-check.sh` (becomes language-aware).
Apply the same split to `test.sh` (→ `test-swift.sh`, `test-python.sh` called
by a wrapper).

`proto-gen.sh` is already single-purpose and requires no restructuring — it
is carried forward unchanged into the unified template.

`agent-run.sh` — the launcher script that applies read-only permission flags
(Claude: `--permission-mode bypassPermissions`, `--disallowedTools git commit/push`;
Codex: `--sandbox read-only`, `-a never`) to agents that should never write
files — must be updated for v9: rename `apple-architect` → `architect` in its
READONLY_AGENTS list, add `auditor` and its six subagents to READONLY_AGENTS.
Gemini CLI invocation differs fundamentally from Claude and Codex (no `--agent`
flag; agents are activated via skills and GEMINI.md role sections) — the exact
mechanism for Gemini support in `agent-run.sh` is designed and resolved in Step 9.

Scripts are tool-agnostic — any of the three AI tools invokes them identically.

**Rationale:** A single `validate.sh` handling Swift, Python, and proto with
nested conditionals becomes hard to debug when one toolchain fails and the
others are fine. Separate scripts produce separate exit codes and separate
error messages. The wrapper maintains backward compatibility — agent prompts
still say "run `./scripts/validate.sh`".

**Alternatives rejected:**
- *One script per template (current model extended):* Rejected — under the unified
  template, there is no template-per-language structure to anchor language-specific
  scripts to.
- *Fully separate scripts with no wrapper:* Rejected — requires updating every
  agent prompt that references `validate.sh`.

---

### Decision 5 — Cross-tool parity: what is identical vs. intentionally different

**What must be identical across Claude, Codex, and Gemini:**
- Skill content (SKILL.md files) — identical; the format is cross-platform
- Project documents (ARCHITECTURE.md, IMPLEMENTATION_PLAN.md, etc.) — identical
- Scripts — identical; tool-agnostic shell commands
- BACKLOG.md, STATUS.md, CHANGELOG.md — identical; shared state

**What is intentionally different:**
- Context file names: `CLAUDE.md` / `AGENTS.md` / `GEMINI.md`
- Agent file format: `.claude/agents/` (markdown) / `.codex/agents/` (TOML) /
  GEMINI.md sections (no separate files)
- Skill loading trigger: Claude auto-loads descriptions; Codex loads on-demand
  via project docs listing; Gemini uses `activate_skill` tool
- MCP configuration: `~/.claude/` / `~/.codex/config.toml` / `~/.gemini/settings.json`
- Approval model default: varies by tool (see TOOL-COMPARISON.md)
- Local model support: Codex `config.toml` supports local model providers (Ollama,
  LM Studio) via `[model_providers]` config and multiple model profiles
  (cloud-default, local-light, local-code). Claude Code and Gemini CLI do not
  have equivalent built-in local model profile switching. The v9 unified template
  preserves all Codex model profiles and local provider configuration.

**Rationale:** Forcing identical formats where tools use different native formats
produces worse results. A TOML agent file for Codex is more reliable than a
markdown file converted to TOML. The goal is behavioral parity — same agents,
same skills, same knowledge — not file format parity.

---

### Decision 6 — The auditor agent

**Decision:** Add a new `auditor` agent for full-codebase structural audits.
Unlike `reviewer` (single-phase code review) and `tester` (test strategy), the
auditor reads the entire codebase and evaluates it across multiple quality
dimensions simultaneously. It is read-only. It uses the `audit-methodology`
skill plus platform skills loaded for the project.

**Audit dimensions:**
- Architecture compliance (layer boundaries, LSP, concrete type leakage)
- Design quality (SOLID, coupling, interface uniformity)
- Coding best practices (language-specific idioms, error handling, dead code)
- Test quality (coverage gaps, test design, isolation)
- Documentation accuracy (docs vs. actual code)
- Deployment readiness (platform-specific: signing/notarization for Apple,
  container security for Python)
- UI/UX compliance (view thickness, accessibility, incomplete states)
- Performance patterns (identifiable anti-patterns causing measurable problems)
- Security (credential exposure, unsafe deserialization, injection vectors)

**Subagent architecture (v9 implementation):** The auditor spawns one subagent
per audit cluster. The parent auditor coordinates the subagents and consolidates
their reports into a single structured output. This is the primary implementation
approach — not a future upgrade. The subagent design serves two purposes: it
keeps each subagent's context focused (only the files relevant to its cluster),
and it provides a working example of subagent orchestration for the pack's users
to reference when designing their own multi-agent workflows.

Six subagents, each covering a semantically coherent cluster of audit dimensions:

- `audit-architecture` — architecture compliance + design quality (layer
  boundaries, LSP compliance, concrete type leakage, SOLID adherence, coupling,
  interface uniformity)
- `audit-code` — coding best practices + performance patterns (language-specific
  idioms, error handling, dead code, identifiable performance anti-patterns
  causing measurable problems)
- `audit-tests` — test quality (coverage gaps, test design quality, isolation,
  missing edge cases)
- `audit-docs` — documentation accuracy (markdown vs. actual code, stale
  descriptions, wrong file paths, CHANGELOG drift)
- `audit-security` — security (credential exposure, unsafe deserialization,
  injection vectors, sensitive data in logs)
- `audit-ui` — UI/UX compliance + deployment readiness (view thickness,
  accessibility, incomplete states, platform-specific deployment config:
  signing/notarization for Apple, container security for Python)

The parent auditor receives all subagent reports and produces a consolidated
report using the `audit-methodology` skill's output format. Platform skills
(e.g., `deployment-apple`, `deployment-python`, `security-patterns`) are loaded
by the relevant subagents, not the parent.

**Alternatives rejected:**
- *Single-agent audit:* Rejected — a single agent reading the entire codebase
  across all dimensions produces diffuse output and hits context limits on large
  projects. Subagents allow each dimension to be thorough.
- *One auditor per platform:* Rejected — this is the proliferation problem. Platform
  knowledge goes in skills loaded by the relevant subagent.

---

### Decision 7 — Agent and skill governance

**Decision:** Adding a new agent or skill to the pack is a pack version event,
not a project-level customization. It requires updating multiple files in a
coordinated commit and is tracked as a BD item. Project-level customization
(adding agents or skills directly to a project without contributing them to the
pack) is permitted but carries documented risks and must follow a declared
protocol.

**Pack-level addition checklist (required for every new agent or skill):**

When a new agent or skill is added to the pack, all of the following must be
updated in the same commit or the immediately following one:

| File | Required change |
|---|---|
| `AGENTS.md` | Add agent role section or update skill references (Codex context file) |
| `CLAUDE.md` (template) | Add agent to routing table if it changes when to use what |
| `GEMINI.md` (template) | Add agent role section or skill reference |
| `PACK-AGENTS.md` (pack repo) | Update the pack repo's agent routing table for pack development workflows |
| `PLATFORM-SKILLS.md` | Add skill to selection matrix if it changes skill combinations |
| `supporting-docs/DEPENDENCIES.md` | Add any new tool dependencies the agent or skill requires |
| `maintenance-docs/TOOL-COMPARISON.md` | Add agent if its behavior differs meaningfully across tools |
| `supporting-docs/METHODOLOGY.md` | Add a workflow entry if the agent introduces a new workflow |
| `supporting-docs/PROMPT-TEMPLATES.md` | Add a prompt template for the new agent |
| `QUICKSTART.md` | Update if setup steps change for new projects |
| `CHANGELOG.md` | Add version entry |
| `README.md` | Update version table |

This is non-trivial by design. An agent or skill that cannot be fully documented
across these files is not ready to be added to the pack.

**Project-level customization — permitted with caution:**

A developer may add a custom agent or skill directly to their project's
`.claude/agents/`, `.codex/agents/`, or `.claude/skills/` directories.
This is technically supported by all three tools but creates the following risks:

> ⚠️ **Custom agents and skills are invisible to the PM chat unless explicitly
> documented.** The PM chat generates prompts based on AGENTS.md, CLAUDE.md,
> and PLATFORM-SKILLS.md. An undocumented custom agent will not appear in
> routing tables and will not be used correctly. An undocumented custom skill
> will not be loaded by the PM chat when generating prompts.
>
> **If you add a custom agent or skill to your project:**
> 1. Add it to METHODOLOGY.md Part 3 routing table so the PM chat knows it exists
> 2. Add it to your project's CLAUDE.md and GEMINI.md
> 3. Add the agent role to your project's AGENTS.md (Codex context file)
> 4. Add it to your project's PLATFORM-SKILLS.md if it changes skill selection
> 5. Document it in your project's ARCHITECTURE.md under "Custom agents/skills"
> 6. Note that pack upgrades will not update custom files — you are responsible
>    for maintaining them through version changes
>
> **Prefer contributing useful agents and skills back to the pack** rather than
> maintaining project-local customizations. Open a BD item in the pack backlog.

**Rationale:** The pack's value is consistency. An undocumented custom agent
that the PM chat doesn't know about is worse than no agent at all — it silently
diverges from the documented workflow and produces unpredictable behavior during
reviewer cycles and audits.

**Alternatives rejected:**
- *No project-level customization allowed:* Rejected — too restrictive; valid
  project-specific needs exist (e.g., a specialized docs-researcher for a
  proprietary API that is not suitable for the general pack).
- *Allow customization without documentation requirements:* Rejected — invisible
  agents produce undefined PM chat behavior.

---

### Decision 8 — Agent selection criteria are explicit and live in METHODOLOGY.md

**Decision:** All conditional agents — tester, auditor, and planner — have
explicit documented trigger conditions in METHODOLOGY.md Part 3 ("When to use
each agent"). The PM chat must never rely on implicit judgment to decide whether
to invoke these agents. The criteria must be concrete enough that a PM chat
session with no prior project history can make the correct routing decision
from the table alone.

**Tester vs. auditor vs. reviewer — distinguished by timing and purpose:**

These three agents all touch code quality but are mutually exclusive in when
and why they are used:

- **Reviewer** — retrospective, per-phase gate, always required. Runs after
  every coder pass. Scoped to one phase. Cannot be skipped. Answers: "does
  this phase's code meet the implementation plan?"
- **Tester** — prospective, prescriptive, conditional. Used *before* complex
  implementation to design the test strategy. Output is a specification telling
  the coder what tests to build. Triggered when test infrastructure (mocks,
  actors, async streams, UI harness) is complex enough that leaving it to the
  coder's judgment risks getting it wrong. Answers: "what tests should exist
  and how should they be structured?"
- **Auditor** — retrospective, diagnostic, periodic. Used *after* substantial
  implementation to find systemic gaps across the full codebase. Never used
  before implementation exists. Output is a problem report across multiple
  dimensions. Answers: "what gaps and structural problems exist across the
  whole codebase?"

Tester and auditor are mutually exclusive by timing. You run tester before the
coder; you run auditor after multiple phases are complete.

**Planner trigger conditions (must be part of the phase gate check):**

The planner check runs as part of Procedure 1 (phase gate check) in
METHODOLOGY.md Part 7 — before generating any coder prompt. If any of these
conditions is true, the planner runs first:

1. The phase has more than ~5 tasks, or task dependencies within the phase
   are non-linear (one task must complete before another can start, and this
   is not already spelled out in the implementation plan)
2. The PM chat cannot map the implementation plan's phase description to
   discrete, independently verifiable tasks without ambiguity
3. A coder has failed the same phase twice without meaningful progress and
   the cause appears to be task definition rather than architecture (an
   architecture cause would trigger the architect via Workflow 4 instead)

**What METHODOLOGY.md Part 3 must contain after v9:**
- The existing "When to use each agent" routing table
- An explicit tester trigger rule
- An explicit auditor trigger rule (periodic milestone, not per-phase)
- The planner trigger conditions, cross-referenced to Procedure 1
- A clear disambiguation table showing reviewer vs. tester vs. auditor

**Rationale:** Implicit PM chat judgment produces inconsistent behavior across
sessions and tools. A fresh session on Gemini CLI has no context from prior
decisions and must be able to route correctly from the documented table alone.

**Alternatives rejected:**
- *Put criteria in AGENTS.md:* Rejected — AGENTS.md in the project template is
  Codex's agent configuration file. It is not a shared PM chat reference.
- *Put criteria in PLATFORM-SKILLS.md:* Rejected — that document is the skill
  selection matrix, not the agent routing table. Mixing concerns would bloat it.
- *Keep implicit judgment:* Rejected — produces inconsistent behavior and breaks
  down on fresh sessions and cross-tool switches.

---

## Part 3 — PM Chat Architecture

The PM chat is the long-running conversational workspace that holds all project
decisions, generates all agent prompts, and receives all agent output. It is
not an agent. Understanding how the PM chat works on each tool is essential
because v9 is designed to be fully usable on all three.

### The cross-tool continuity principle

The project documents are the shared state. `IMPLEMENTATION_PLAN.md`,
`STATUS.md`, `BACKLOG.md`, and `CHANGELOG.md` are committed to the repo. Any
PM chat on any tool can reconstruct project state by reading those four files
at startup. The startup skill on each tool does exactly this.

Conversation history is not portable and is not intended to be. `ARCHITECTURE.md`
is the permanent record of architectural decisions — not the conversation that
produced them. Every significant decision must be written into project docs
before the session ends.

### Architecture A — Claude Web Projects (primary, richest capability)

Project knowledge is stored in the cloud and searchable via GitHub connector.
Conversations persist indefinitely across sessions and machines. Desktop
Commander (via MCP in Claude Desktop app) provides file write capability.

*File write mechanism:* Desktop Commander (Claude Desktop) or output content
for manual application (Claude Web without Desktop).
*Session resume:* Persistent — return to the same project conversation.
*Context compression:* Project knowledge search retrieves relevant content on
demand rather than loading the full repo into context. For long conversations,
start a new conversation within the project — project knowledge persists across
conversations automatically.
*Cross-machine:* Cloud-hosted; accessible from any machine.

### Architecture B — Gemini CLI (capable, locally-hosted)

GEMINI.md hierarchy provides persistent project rules loaded automatically.
`/chat save <tag>` saves session state to disk. `/chat resume <tag>` restores
it. `save_memory` writes cross-session facts to `~/.gemini/GEMINI.md`.
`/compress` handles context compression. Checkpointing provides automatic
snapshots. Plan Mode (current default) is read-only before any edits.

*File write mechanism:* Gemini CLI native file write tools.
*Session resume:* `/chat resume <tag>` — must save explicitly before exiting.
*Context compression:* `/compress` summarizes conversation history.
*Cross-machine:* Local only. Session files are not portable. State is recovered
via project docs (git pull + pm-startup skill).
*No GitHub connector:* PM chat reads files via filesystem access only. The
pm-startup skill reads the four key state docs at session start.

### Architecture C — ChatGPT Web / Codex (functional, cloud-hosted)

ChatGPT Web threads persist across sessions. Custom instructions provide
persistent context rules. GitHub connector provides basic repo read access
(less sophisticated than Claude Projects — keyword search, not semantic).
No native file write — file changes must be output as content for manual
application or run via Codex CLI.

*File write mechanism:* Manual — output content, developer applies.
*Session resume:* Persistent threads; no explicit save required.
*Context compression:* None built in — long threads degrade without manual
management (start a new thread and re-paste key context).
*Cross-machine:* Cloud-hosted; accessible from any machine.

### PM chat switching mid-project

Switching PM chat tools mid-project is supported. The startup skill on each
tool reads the four key state docs and reconstructs context. What is not
preserved across a switch is the reasoning behind past decisions. This is why
ARCHITECTURE.md must capture all architectural decisions with rationale — it
is the permanent record, not the conversation history.

### PM chat skill selection responsibility

Under the unified model, the PM chat is responsible for knowing which skills
to load for each agent for each project type. The skill selection matrix in
Part 2 Decision 3 is the reference. The PM chat reads `PLATFORM-SKILLS.md` — a doc created as part of Step 5 — for the authoritative selection table. METHODOLOGY.md and PROMPT-TEMPLATES.md
are not the right place for this — they would become bloated. PLATFORM-SKILLS.md
is a focused reference that any PM chat can read at prompt-generation time.

---

## Part 4 — Documentation Changes

### New documents to create

| Document | Location | Purpose |
|---|---|---|
| `GEMINI.md` | Template root | Gemini CLI context file; equivalent to CLAUDE.md |
| `PLATFORM-SKILLS.md` | Template root | PM chat skill-selection matrix by project type and agent |
| `supporting-docs/MIGRATION-v8-to-v9.md` | supporting-docs/ | Upgrade guide for existing projects |

*Note: `maintenance-docs/TOOL-COMPARISON.md` was created during the v9 planning
phase and committed in Step 1. It does not need to be created during implementation.*

### Documents to expand or restructure

| Document | Change |
|---|---|
| `QUICKSTART.md` | Update for unified template: single template directory, three-tool setup (Claude/Codex/Gemini), GEMINI.md creation, skill loading, PLATFORM-SKILLS.md reference. Currently describes three template directories and Claude-only setup. |
| `supporting-docs/AGENT_KICKOFF_TEMPLATE.md` | Update architect kickoff to specify which skills to load rather than which template-specific architecture to adopt. Currently references platform-specific patterns scoped to the old three-template model. |
| `PM-CHAT.md` (template — project-level file) | Expand to cover all three PM chat architectures, their startup procedures, file write mechanisms, context compression, and cross-tool switching. Note: the project-level PM-CHAT.md is copied from `supporting-docs/PM-CHAT.md` during setup — Step 5 updates the supporting-docs source so all new projects get the three-tool version. |
| `supporting-docs/CLI-PM-SETUP.md` | Update for three-tool coverage: add Gemini CLI session management (`/chat save`, `/chat resume`, `/compress`) alongside existing Claude CLI content. Update cross-machine workflow for all three tools. |
| `supporting-docs/DEPENDENCIES.md` | Add Codex CLI and Gemini CLI; add Node.js as a shared dependency; add future C/C++ tools. |
| `supporting-docs/METHODOLOGY.md` | Add context window guidance per agent type; add approval model documentation per tool; add skill-loading preamble referencing PLATFORM-SKILLS.md; add agent/skill governance rules; add explicit routing criteria for tester, auditor, and planner with trigger conditions (see Decision 8). |
| `AGENTS.md` | Update to be a clean Codex-only agent context file. The human-readable routing table and agent selection criteria move to METHODOLOGY.md Part 3 per Decision 8. Remove any content that is not Codex-specific. |
| `supporting-docs/SETUP_TEMPLATE.md` | Update for unified template: remove references to three template directories; update setup instructions for all three tools. |
| `supporting-docs/PROMPT-TEMPLATES.md` | Evaluate Templates 9–12 (global audit prompts currently using tester and docs-researcher) for revision or deprecation as the auditor agent is designed (Step 10). Add auditor prompt template (Step 11). No other structural changes required. |
| `xcode-companion-templates/ClaudeAgentConfig/CLAUDE.md` | Update agent name references: `apple-architect` → `architect`. Update skill names to match v9 skill library. |

### Pack-root items that remain unchanged

The following are pack-root level items — they do not move into the unified
template and require no structural changes in v9:

- `shared-docs/` — reference notes and iOS 26 documentation; stays at pack root
- `sync-xcode-docs.sh` — iOS 26 doc sync script; stays at pack root
- `vscode-companion-templates/` — machine-level VS Code config; stays at pack root
- `maintenance-docs/origins/swift-python-best-practices-v3.md` — source reference for
  skill content in Step 4; will be explicitly cited in skill file development

The `xcode-companion-templates/` directory stays at pack root but its
`ClaudeAgentConfig/CLAUDE.md` requires updating (see "Documents to expand"
table above).

### Documents to consolidate or remove

| Document | Action |
|---|---|
| `maintenance-docs/GEMINI-CLI-ANALYSIS.md` | Absorb key findings into TOOL-COMPARISON.md; deprecate original |
| `maintenance-docs/ANDROID-ANALYSIS.md` | Absorb key findings into TOOL-COMPARISON.md; deprecate original |

### Documents that remain structurally stable

`METHODOLOGY.md` workflow structure remains stable — new content is added,
existing workflows are not removed. `PROMPT-TEMPLATES.md` overall structure
remains stable; Templates 9–12 are evaluated in Step 10 and may be deprecated
— if so, numbering gaps are acceptable and remaining templates are not
renumbered. `BACKLOG.md` format and procedures, `CHANGELOG.md` format — all
remain stable. v9 is a structural redesign, not a methodology redesign.

---

## Part 5 — Backlog Map

| BD | Title | v9 Disposition |
|---|---|---|
| BD-020 | C++ server support analysis | Keep open — scope updated to skill analysis not template |
| BD-021 | Apple platform skills redesign (three-tier) | Deprecated → superseded by BD-024 |
| BD-022 | C project template and c-language skill | Deprecated → c-language skill lives in BD-024; template directory dropped |
| BD-023 | Mixed-language skills for Apple projects | Deprecated → all skills absorbed into BD-024 skill library |
| BD-024 | Unified template and platform skills redesign | Core v9 work — see Part 6 for implementation steps |
| BD-025 | Update DEPENDENCIES.md for Codex and Gemini CLIs | Independent of BD-024; can run in parallel |
| BD-026 | Split scripts by language/platform | Part of BD-024 scope (Step 9 in Part 6) |
| BD-027 | Auditor agent design and implementation | Part of BD-024 scope (Steps 10–11 in Part 6) |
| BD-028 | PM-CHAT.md expansion for all three tools | Part of BD-024 scope (Step 5 in Part 6) |
| BD-029 | Pack self-validation CI/CD | Independent of BD-024; post-v9 |
| BD-030 | TOOL-COMPARISON.md (living reference) | Resolves at Step 1 — committed as part of planning docs |
| BD-031 | Evaluate publishing pack skills to skills.sh | Deferred — post-v9, after skills are stable |

---

## Part 6 — Implementation Sequence

> **How to use this section:**
> Each step is sized to fit within a single PM chat working session. If a step
> feels too large to complete in one session, split it before starting. Steps
> are ordered so that nothing is blocked by a later step, but earlier steps may
> be dependencies. The format — problem, goal, success — is intentionally
> non-prescriptive and consistent with the pack's own Prompt Authoring Principles.
> This section describes what needs to be true, not how to get there.
>
> **Branch strategy:** v9 implementation work happens on the `v9-dev` branch.
> The `main` branch continues to receive v8.x patches (v8.10, v8.11, etc.)
> without interference. Step 1 creates the branch. If a v8.x patch on main
> touches a file that v9-dev also modifies, cherry-pick the patch onto v9-dev
> after it lands on main. When Step 15 passes, merge `v9-dev` → `main` and
> tag `v9.0`.

---

### Step 1 — Finalize and commit the v9 planning documents

**Problem:** The v9 design exists in conversation history and working files on
disk but has not been committed to the repo. Future sessions on any tool cannot
access it. The BACKLOG.md update reflecting BD-020 through BD-031 is also
uncommitted. Additionally, several operational pack files have been modified on
disk (CLAUDE.md, AGENTS.md, GEMINI.md, PACK-AGENTS.md, PACK-CHAT.md) — these
govern how the CLI pack chat behaves and must not be committed to main while
v8.x work is ongoing, to avoid confusing a v8.x PM chat session with v9-only
operational changes.

**Goal:** V9-DESIGN.md, TOOL-COMPARISON.md, and the updated BACKLOG.md are
committed to main and visible via the GitHub connector. A `v9-dev` branch is
created immediately after. The operational file changes are committed on `v9-dev`
only, not on main. The v9 planning phase is officially closed. v8.x patches
continue on main unaffected.

**Success looks like:** `git log` on main shows a commit containing only
V9-DESIGN.md, TOOL-COMPARISON.md, and BACKLOG.md — no operational file changes.
The `v8.10` tag points to this commit. The `v8` tag floats to `v8.10`. A `v9-dev`
branch exists from this commit. The GitHub connector returns results from
V9-DESIGN.md when queried. BACKLOG.md shows BD-020 as Open (scope updated),
BD-021 through BD-023 as Deprecated, and BD-024 through BD-031 as Open or
Deferred. The operational files (CLAUDE.md, AGENTS.md, GEMINI.md, PACK-AGENTS.md,
PACK-CHAT.md) are committed on `v9-dev` as the first commit on that branch.

**Depends on:** None.
**Resolves:** BD-030; closes the planning phase; enables all subsequent steps.

---

### Step 2 — Deprecate superseded analysis files

**Problem:** Two point-in-time analysis files (GEMINI-CLI-ANALYSIS.md and
ANDROID-ANALYSIS.md) remain in supporting-docs/ without deprecation notices,
creating a risk that a PM chat session reads them as current references rather
than using TOOL-COMPARISON.md. TOOL-COMPARISON.md was committed in Step 1 but
has not yet been cross-referenced from these older files.

**Goal:** Both superseded files contain a deprecation notice at the top pointing
to TOOL-COMPARISON.md. A PM chat reading either file immediately knows it is
historical and where to find current information.

**Success looks like:** The first visible content in both files is a clearly
formatted deprecation notice naming TOOL-COMPARISON.md as the replacement.
A PM chat asked about Gemini CLI capabilities reads TOOL-COMPARISON.md, not
GEMINI-CLI-ANALYSIS.md.

**Depends on:** None.
**Resolves:** No BD item — housekeeping step following Step 1.

---

### Step 3 — Design the unified template structure

**Problem:** The current three template directories have overlapping content
and no clear structural contract for what a unified template must contain.
Several structural questions are currently unresolved and block subsequent
steps: the unified template directory name, how bootstrap.sh detects platform,
where skills live within the template, which files are pack-provided vs.
project-specific, and the grpc-schema disposition (dedicated agent vs. skill).
None of these can be answered by Steps 4–11 without this design being settled first.

Additionally, the following file categories exist in v8.9 templates and must
each be explicitly placed in the unified template design — included, excluded,
merged, or conditionally generated:

- Agent files: `.claude/agents/` (markdown), `.codex/agents/` (TOML), GEMINI.md sections
- Skill directories: `.claude/skills/`, `.codex/skills/` (Gemini skills location TBD)
- Scripts: `format.sh`, `validate.sh`, `bootstrap.sh`, `test.sh`, `proto-gen.sh`,
  `agent-post-edit-check.sh`, `agent-run.sh` (language-specific variants of each)
- Codex config: `.codex/config.toml` (with model profiles and `post_edit_command`),
  `.codex/requirements.toml`
- Claude config: `.claude/settings.json`, `.claude/settings.local.example.json`
- MCP config: `.mcp.json.example` (including mcp-local-rag configuration)
- Context files: `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`
  (three tool-native context files; `PACK-AGENTS.md` is pack-repo-only and never in a project template)
- PM chat files: `PM-CHAT.md`, `PLATFORM-SKILLS.md`
- Proto scaffold: `proto/` directory structure, `buf.gen.yaml`, `buf.yaml`
- Python project files: `pyproject.toml`, `pyrightconfig.json`, `server/` layout
  (language-specific — must not appear in Swift-only projects)
- Pack root items that stay at pack root (not in unified template):
  `shared-docs/`, `sync-xcode-docs.sh`, `xcode-companion-templates/`,
  `vscode-companion-templates/`, `supporting-docs/`, `maintenance-docs/`
- Template-level docs: `README.md`, `QUICKSTART.md`, `AGENT_KICKOFF_TEMPLATE.md`

**Goal:** A written structural specification exists — added as a new Decision 9
in Part 2 of this document — describing every file and directory in the unified
template, with notes on which files are pack-provided vs. project-specific,
which are conditionally included based on platform, and which live at pack root.

**Success looks like:** The specification is reviewed and approved. It explicitly
resolves: the unified template directory name, where skills live within it,
which files are pack-provided vs. project-specific, how bootstrap.sh detects
platform, the grpc-schema disposition (dedicated agent vs. skill), and the
placement of every file category listed above. No implementation step depends
on an unresolved structural question after Step 3.

**Depends on:** Step 1.
**Resolves:** No BD item — internal design step required before Steps 4–11.

---

### Step 4 — Create and validate the skill library

**Problem:** The v9 skill library described in Part 2 Decision 3 is not fully
in place. Specifically: the 13 new Tier 2 platform-knowledge skills do not exist
yet and must be created. The existing Tier 1 role-based skills exist only in
`.claude/skills/` (and partially in `.codex/skills/`) — they must be confirmed
to exist correctly in all three tools' skill directories in the unified template.
The `ios-architecture` and `grpc-schema` skills require merging/renaming work
per the Decision 3 footnotes.

**Goal:** All Tier 1 and Tier 2 skills listed in the Part 2 Decision 3 tables
exist as SKILL.md files in the appropriate skills directories for all three tools,
with correct frontmatter (name, description, allowed-tools), accurate content,
and descriptions tight enough to trigger correct activation in Codex and Gemini's
on-demand loading models. The `ios-architecture` merge and `grpc-schema` →
`grpc-patterns` rename are implemented. Skills that previously existed only in
the combined template (`api-design`, `python-architecture`) now exist in the
unified template.

**Success looks like:** Each skill file passes a structural check (valid
frontmatter, non-empty content). All Tier 1 skills exist in `.claude/skills/`,
`.codex/skills/`, and `.gemini/skills/` in the unified template. The
`grpc-schema` Tier 1 skill is absent from all three (superseded by `grpc-patterns`
Tier 2). The `ios-architecture` Tier 2 skill incorporates the content of the
former `ios-architecture` Tier 1 skill. A spot-check of three Tier 2 skills
across Claude Code, Codex, and Gemini CLI confirms each loads correctly and
activates when expected. The `audit-methodology` skill produces consistent
report structure across tools. The `swift-best-practices` and
`python-best-practices` skills reference `maintenance-docs/origins/swift-python-best-practices-v3.md`
as a source in their content.

**Depends on:** Step 3 (structure must be confirmed before skill file locations
are finalized).
**Resolves:** Core of BD-024; absorbs BD-021, BD-022, BD-023 skill content.

---

### Step 5 — Create the PM chat supporting documents

**Problem:** Three PM chat documents are missing or incomplete: `PM-CHAT.md`
(template) does not cover Codex or Gemini; `PLATFORM-SKILLS.md` does not exist;
the template `GEMINI.md` does not exist. Without these, the PM chat on Codex
and Gemini cannot operate correctly, and the PM chat on any tool cannot reliably
select the right skills for each project type.

**Goal:** All three documents exist in the unified template: `PM-CHAT.md`
(the project-level PM chat instructions file, distinct from `supporting-docs/PM-CHAT.md`
which is the pack-level reference) covering all three PM chat architectures with
startup procedures, file write mechanisms, context compression, and cross-tool
switching; `PLATFORM-SKILLS.md` containing the authoritative skill-selection
matrix by project type and agent; `GEMINI.md` (the project template context file
for Gemini CLI, distinct from the pack repo's own `GEMINI.md` for pack development)
providing Gemini CLI context equivalent to CLAUDE.md.

Also in scope for this step: update the `pm-startup` skill to include
`PLATFORM-SKILLS.md` in its RAG freshness check and ingestion alongside
`METHODOLOGY.md` and `PROMPT-TEMPLATES.md`. Decide and document whether
`pm-startup` is ported to `.codex/skills/` and `.gemini/skills/` in v9 (it
currently exists only in `.claude/skills/`), or whether each tool gets a
different startup mechanism — for example, Gemini CLI's `save_memory` combined
with GEMINI.md hierarchy, and Codex CLI's `--resume` flag combined with ChatGPT
Web custom instructions. The v9 PM-CHAT.md must document the startup procedure
for each tool regardless of which mechanism is chosen. Update `.mcp.json.example`
to reflect the unified template path structure and confirm mcp-local-rag remains
the correct tool for CLI PM chat semantic search. Document whether Gemini CLI's
native GEMINI.md hierarchy is sufficient for semantic search over pack reference
docs, or whether mcp-local-rag is also recommended for Gemini CLI PM chat sessions.

**Success looks like:** A developer starting a new project on Gemini CLI can
read `PM-CHAT.md` and `GEMINI.md` and operate the PM chat correctly without
referring to any other documentation. The skill-selection matrix in
`PLATFORM-SKILLS.md` matches the table in Part 2 Decision 3 of this document.
The `pm-startup` skill's RAG freshness check covers `METHODOLOGY.md`,
`PROMPT-TEMPLATES.md`, and `PLATFORM-SKILLS.md`. The startup mechanism for
each tool (Claude, Codex, Gemini) is documented and implemented — whether via
a ported `pm-startup` skill or tool-native alternatives. The question of whether
mcp-local-rag is recommended for Gemini CLI PM chat is answered and documented.

**Depends on:** Steps 3 and 4 (structure confirmed, skill names finalized).
**Resolves:** BD-028; part of BD-024.

---

### Step 6 — Generalize the agent files (Claude)

**Problem:** The Claude agent files in the three template directories contain
platform-specific knowledge (architecture rules, forbidden patterns, Swift/Python
specifics) that belongs in skills, not agent definitions. The `apple-architect`
and `python-architect` agents need to be merged into a single `architect` agent.
Agent files that reference template-specific paths or tools need to be updated.

**Goal:** A single set of platform-agnostic Claude agent files exists in the
unified template's `.claude/agents/` directory. The `architect` agent's system
prompt references skills rather than encoding platform knowledge directly. All
other agent files are reviewed and updated to remove any template-specific
references.

**Success looks like:** Running an architect pass on a macOS Swift project (with
the correct platform skills loaded) and on a Python gRPC server project (with
the correct platform skills loaded) produces correct, platform-appropriate output
from a single agent file. No context file or agent definition hardcodes platform
rules — all platform-specific rules live in skills. Context files reference skill
names and provide workflow rules only.

**Depends on:** Steps 3, 4, and 5 (structure, skills, and PM chat skill
selection must be in place before agents can reference skills correctly).
**Resolves:** Core of BD-024; resolves the apple-architect/python-architect
merge.

---

### Step 7 — Create or convert Codex agent files

**Problem:** The Codex agent files (`.codex/agents/*.toml`) are currently
maintained in three separate template directories with the same platform
duplication as the Claude files. They need to be consolidated into one unified
set and updated to reference skills rather than encoding platform knowledge.
The grpc-schema disposition was decided in Step 3 — this step implements that
decision.

**Goal:** A single set of Codex agent TOML files exists in the unified
template's `.codex/agents/` directory. The content is behaviorally equivalent
to the Claude agent files from Step 6. The grpc-schema disposition is resolved
and implemented.

**Success looks like:** A Codex CLI session using these agent files produces
equivalent results to a Claude Code session using the Claude agent files from
Step 6, for the same task with the same skills loaded. The `config.toml`
`[agents]` threading settings (`max_threads`, `max_depth`) are reviewed and
updated if necessary to support the auditor's six subagents — the current
`max_depth = 1` may need to increase to allow the parent-subagent relationship.

**Depends on:** Step 6 (Claude agent files are the reference for Codex equivalents).
**Resolves:** Part of BD-024; Codex parity for agents.

---

### Step 8 — Configure Gemini agent behavior in GEMINI.md

**Problem:** Gemini CLI does not use a `.gemini/agents/` directory with
dedicated agent files. Agent-like behavior must be defined via GEMINI.md
sections and skills. The current pack has no Gemini agent configuration at all.

**Goal:** GEMINI.md (created in Step 5) contains sections that define each
agent role's behavior for Gemini CLI, equivalent in intent to the Claude and
Codex agent files. Subagent configuration for Gemini (if needed) is included.

**Success looks like:** A Gemini CLI session with the correct GEMINI.md
produces agent behavior equivalent to Claude Code and Codex for the same task
with the same skills loaded. The reviewer running in Plan Mode behaves
correctly. The coder agent applies the right skill constraints.

**Depends on:** Steps 5 and 6 (GEMINI.md and Claude agent files as reference).
**Resolves:** Part of BD-024; Gemini parity for agents.

---

### Step 9 — Restructure scripts

**Problem:** The current scripts (`format.sh`, `validate.sh`) are monolithic
per template. Under the unified template, they must support multiple languages
and build environments without becoming tangled conditional logic. Language-
specific scripts need to exist alongside wrapper scripts for backward
compatibility.

**Goal:** The unified template's `scripts/` directory contains language-specific
scripts (`format-swift.sh`, `format-python.sh`, `validate-swift.sh`,
`validate-python.sh`, `validate-proto.sh`, `bootstrap-swift.sh`,
`bootstrap-python.sh`, `test-swift.sh`, `test-python.sh`) plus wrapper scripts
(`format.sh`, `validate.sh`, `bootstrap.sh`, `test.sh`) that detect which
language-specific scripts apply and call them. `proto-gen.sh` is carried
forward unchanged. `agent-post-edit-check.sh` is updated to be language-aware.
`agent-run.sh` is updated for the v9 unified agent roster: `apple-architect`
renamed to `architect`, `auditor` and its six subagents added to READONLY_AGENTS,
and Gemini CLI invocation added as a third supported CLI alongside Claude and
Codex. All scripts are tool-agnostic and work on macOS and Linux (WSL-compatible).

**Success looks like:** Running `./scripts/validate.sh` in a Swift-only project
calls only `validate-swift.sh`. Running it in a Python+proto project calls
`validate-python.sh` and `validate-proto.sh`. Running `./scripts/bootstrap.sh`
installs only the dependencies required for the detected project type.
`agent-post-edit-check.sh` correctly validates a `.swift` file edit without
running Python tooling and vice versa. `agent-run.sh` correctly applies
read-only flags when invoking `auditor` or any subagent on Claude and Codex.
Gemini CLI invocation behavior is designed, documented, and implemented — either
via `agent-run.sh` Gemini support or a clearly documented alternative mechanism.
The `config.toml` `post_edit_command` reference remains valid and points to
the updated `agent-post-edit-check.sh`. A new language can be added by adding
one set of `<task>-<lang>.sh` files and updating the wrapper detection logic
— no other changes required.

**Depends on:** Step 3 (unified template structure confirmed).
**Resolves:** BD-026; part of BD-024.

---

### Step 10 — Design the auditor agent and its subagents

**Problem:** The auditor agent described in Part 2 Decision 6 does not exist
and cannot be built without a clear design: how the parent auditor coordinates
six subagents, how subagents receive their scope and platform skills, what
the `audit-methodology` skill specifies for the consolidated report format,
how each subagent reports back to the parent, and how the auditor fits into
METHODOLOGY.md as a workflow.

**Goal:** A written auditor design exists covering: the parent-subagent
coordination model, each subagent's scope and which skills it loads, the
`audit-methodology` skill content specification, the consolidated report
format, how the workflow differs from Workflow 5 (global audit) in
METHODOLOGY.md, and which METHODOLOGY.md workflow entry covers the auditor.
The design also documents the auditor as a working subagent reference
example — the pack's users will learn from it. The design must also resolve
the fate of PROMPT-TEMPLATES.md Templates 9–12 (global test coverage audit,
documentation audit, architecture/LSP audit, UI audit) — whether each is
deprecated in favor of the auditor, revised to invoke the auditor, or kept
as supplementary single-dimension prompts.

**Success looks like:** The auditor design is specific enough that all seven
agent files (parent + six subagents) and the `audit-methodology` skill can
be written without further design discussion. The design clearly answers: what
does each subagent receive as input, what does it output, and how does the
parent consolidate those outputs. The design has been reviewed and approved.

**Depends on:** Steps 4 and 6 (skill library and Claude agent file patterns
established before subagent design is finalized).
**Resolves:** Design phase of BD-027.

---

### Step 11 — Implement the auditor agent and its subagents

**Problem:** The auditor design from Step 10 exists but no files do: no parent
auditor agent file, no six subagent files, no `audit-methodology` skill, no
METHODOLOGY.md workflow entry, no PROMPT-TEMPLATES.md template for all three
tools. The auditor must be implemented across Claude, Codex, and Gemini since
it also serves as the pack's working subagent example.

**Goal:** All agent files exist for the parent auditor and all six subagents
across all three tools. The `audit-methodology` skill exists and accurately
describes the consolidated report format and subagent coordination model.
METHODOLOGY.md contains an auditor workflow. PROMPT-TEMPLATES.md contains
an auditor prompt template. The implementation correctly demonstrates
subagent orchestration as a reference pattern.

**Success looks like:** The auditor runs on a known codebase and produces a
consolidated report with correctly attributed findings from each subagent
dimension. Each subagent report is identifiable by its header line (following
the standard report header format from PROMPT-TEMPLATES.md). The consolidated
report matches the `audit-methodology` skill's specified structure. The parent
auditor correctly loads platform skills into the relevant subagents rather
than loading all skills into itself.

**Depends on:** Step 10 (auditor design approved).
**Resolves:** BD-027.

---

### Step 12 — Update shared documentation

**Problem:** Multiple documents contain content specific to the old three-template
structure or are missing information required by the unified model. Specifically:
METHODOLOGY.md lacks context window guidance per agent type, approval model
documentation per tool, skill-loading preamble, agent/skill governance rules,
and explicit routing criteria for tester/auditor/planner (Decision 8).
DEPENDENCIES.md omits Codex CLI and Gemini CLI. AGENTS.md still contains
content beyond Codex-specific rules — the non-Codex content (routing table,
agent selection criteria) must be removed and relocated to METHODOLOGY.md Part 3
per Decision 8. QUICKSTART.md still describes three template
directories and Claude-only setup. AGENT_KICKOFF_TEMPLATE.md still references
platform-specific architecture patterns tied to the old model.
CLI-PM-SETUP.md covers only Claude CLI and needs Gemini CLI coverage.
SETUP_TEMPLATE.md still references the old three-template structure.
xcode-companion-templates/ClaudeAgentConfig/CLAUDE.md references old agent names.

**Goal:** All documents listed in Part 4 "Documents to expand or restructure"
accurately reflect the unified template structure and three-tool support.
METHODOLOGY.md adds all items specified in its Part 4 table row including
Decision 8 agent routing criteria. DEPENDENCIES.md covers all three CLI tools.
AGENTS.md is a clean Codex-only context file. QUICKSTART.md covers unified
template setup for all three tools. AGENT_KICKOFF_TEMPLATE.md references skills
rather than template-specific architecture. CLI-PM-SETUP.md covers Gemini CLI.
SETUP_TEMPLATE.md is updated for the unified template.
xcode-companion-templates/ClaudeAgentConfig/CLAUDE.md uses v9 agent and skill names.

**Success looks like:** A developer reading QUICKSTART.md can set up a new
project on any of the three tools without referring to any other documentation.
METHODOLOGY.md contains all additions specified in its Part 4 table row,
including the explicit agent routing criteria from Decision 8. Decision 8's
cross-references to METHODOLOGY.md sections are verified as accurate after all
additions are made. None of the updated documents reference the old
three-template structure anywhere.

**Depends on:** Steps 3–9 (unified structure and all agent/skill files must
be finalized before documentation can accurately describe them).
**Resolves:** BD-025; part of BD-024.

---

### Step 13 — Write the migration guide and validate upgrade path

**Problem:** Projects currently using v8 have three template directories, two
architect agents, and context files written for the old structure. There is no
documented path to upgrade to v9. Without a tested migration guide, existing
projects cannot safely adopt v9.

**Goal:** `supporting-docs/MIGRATION-v8-to-v9.md` exists and covers: what
changes from v8 to v9, which files to update in an existing project, how to
handle the `apple-architect`/`python-architect` → `architect` rename, how to
add skills to an existing project, how to adopt the new GEMINI.md and
PLATFORM-SKILLS.md files, and how to reinstall the Xcode companion template
files (updated CLAUDE.md with new agent names and skill references must be
copied to `~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/` on
each development machine).

**Success looks like:** The OptiquityTrader project (a known v8 project) can
be migrated to v9 by following the guide without errors or ambiguity. The guide
has been tested by performing the migration on the OptiquityTrader repo and
confirming the project works correctly after migration.

**Depends on:** Steps 3–12 (all v9 files must exist before a migration guide
can be written and tested).
**Resolves:** Final step of BD-024.

---

### Step 14 — Pack self-validation CI/CD

**Problem:** The pack repo has no automated validation. Structural errors —
invalid SKILL.md frontmatter, malformed TOML agent files, broken cross-references
in documentation — are only caught during manual review. As the pack grows,
this becomes a reliability risk.

**Goal:** A GitHub Actions workflow exists in the pack repo that validates on
every push: all SKILL.md files have valid frontmatter (name, description,
allowed-tools), all `.codex/agents/*.toml` files parse correctly, no BACKLOG.md
entries contain TD-TBD sentinels, and the README.md version table is consistent
with the most recent git tag.

**Success looks like:** The workflow runs successfully on the main branch. A
deliberate structural error introduced to a SKILL.md file causes the workflow
to fail with a clear error message. The error is fixed and the workflow passes.

**Depends on:** Steps 3–12 (the files being validated must exist before
validation logic can be written for them).
**Resolves:** BD-029.

### Step 15 — Post-implementation v9 audit and closure

**Problem:** After Steps 3–14 are complete, there is no formal verification
that v9 preserves all v8.9 capabilities and introduces no regressions. The
implementation could be internally consistent but still have silently dropped
a skill, broken a workflow, or failed to cover an edge case that v8.9 handled
correctly. Without a structured closure check, the merge to main could import
a defect that only surfaces when a developer uses a specific flow.

**Goal:** A structured audit compares v9 against the v8.9 capability baseline
using the `v8.9` git tag as the authoritative reference. The audit covers every
category: agents, skills (Tier 1 and Tier 2), PM chat flows on all three tools,
scripts, template documents, migration guide, and the CI/CD validation workflow.
All gaps found are resolved before the `v9-dev` branch is merged to main.

**The audit covers these categories in order:**

1. **Agents** — Every v8.9 agent exists in v9 (with apple-architect and
   python-architect merged to architect). The new auditor and its six subagents
   exist. All agents run on Claude, Codex, and Gemini.

2. **Skills** — Every v8.9 Tier 1 role skill exists in all three tools' skill
   directories. All Tier 2 platform skills exist. `grpc-schema` Tier 1 is
   absent (replaced). `ios-architecture` Tier 2 incorporates Tier 1 content.
   `grpc-patterns` Tier 2 replaces the v8.9 `grpc-schema` role skill.

3. **PM chat flows** — The pm-startup skill (or equivalent) functions on all
   three tools. RAG freshness check covers METHODOLOGY.md, PROMPT-TEMPLATES.md,
   and PLATFORM-SKILLS.md. Skill selection from PLATFORM-SKILLS.md produces
   correct results for macOS Swift, iOS Swift, Python gRPC, and mixed-language
   project types.

4. **Scripts** — All scripts from v8.9 exist in v9 (format, validate, bootstrap,
   test, proto-gen, agent-post-edit-check, agent-run). Language-specific variants
   work correctly. Wrapper detection logic calls only the appropriate variants.
   `agent-run.sh` applies read-only flags correctly for all read-only agents on
   Claude and Codex. Gemini invocation behavior is documented and working.

5. **Template documents** — All template-root files exist: CLAUDE.md, AGENTS.md,
   GEMINI.md, PLATFORM-SKILLS.md, PM-CHAT.md, README.md, QUICKSTART.md,
   AGENT_KICKOFF_TEMPLATE.md. All config files exist: `.claude/settings.json`,
   `.codex/config.toml`, `.codex/requirements.toml`, `.mcp.json.example`. The
   `proto/` scaffold exists. Python project files (`pyproject.toml`,
   `pyrightconfig.json`) are conditionally absent from Swift-only projects.

6. **Documentation** — QUICKSTART.md covers three-tool setup without referencing
   old template directories. METHODOLOGY.md contains all Decision 8 additions.
   DEPENDENCIES.md covers all three CLIs. CLI-PM-SETUP.md covers Gemini CLI.
   SETUP_TEMPLATE.md references the unified template. Xcode companion CLAUDE.md
   uses v9 agent and skill names. MIGRATION-v8-to-v9.md tested successfully on
   OptiquityTrader (Step 13 confirmation).

7. **CI/CD** — The Step 14 GitHub Actions workflow runs and passes on the v9-dev
   branch. A deliberate structural error causes a failure. The error is fixed and
   the workflow passes again.

8. **v8.9 capability diff** — Run `git diff v8.9 HEAD` across template directories
   and confirm every removed or changed file has an explicit account in V9-DESIGN.md
   (either "carried forward," "replaced by," "merged into," "deprecated," or
   "moved to"). No file is unaccounted for.

**Success looks like:** A written audit report exists covering all eight
categories above, with a finding of either "pass" or a listed gap for each
item. All gaps are resolved. The report is committed to `maintenance-docs/` as
`V9-AUDIT-REPORT.md`. The `v9-dev` branch is approved for merge to main.

**Depends on:** Steps 3–14 complete and passing.
**Resolves:** No BD item — validation closure. Enables merge to main and `v9.0` tag.

---

*End of V9-DESIGN.md*
*Do not modify without explicit approval. This is the design record for v9.*
