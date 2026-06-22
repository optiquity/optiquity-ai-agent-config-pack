# CLAUDE.md

<!--
HOW TO USE THIS TEMPLATE

This is the Claude Code context file for your project. It is loaded automatically
by Claude Code CLI at session start via the CLAUDE.md hierarchy.

Fill in [PROJECT_NAME], [PLATFORM_TARGETS], and [TRANSPORT] during project setup.
Fill in the Platform and Stack Defaults section for your project type.
Fill in or remove conditional sections marked with [CONDITIONAL] based on your
project type (e.g., remove iOS 26 section for a Python-only server).
Remove this comment block after filling in the placeholders.

This file is the Claude Code equivalent of AGENTS.md (Codex) and GEMINI.md. All
three files should express the same project rules — only tool-specific operating
notes differ.
-->

---
*Copied from: project-template/CLAUDE.md — AI Agent Config Pack v11*
*Fill in placeholders and remove this block.*
---

**[PROJECT_NAME]** targets [PLATFORM_TARGETS].
Transport: [TRANSPORT] (e.g., gRPC + Proto3 for first-party; REST for third-party).

## Quick reference

- **Pack commands:** run `pack help` for the full verb list, or `/pack-help` in your CLI.
- **Recommended first action:** run `pm-startup` (or your CLI's equivalent).

---

## Capability policy

Claude may perform all major engineering tasks in this repository:
planning, architecture, implementation, refactoring, debugging, testing, code review,
dependency review, repo operations, documentation.

All are allowed. No task category is reserved exclusively for another tool.

Default preference only:
- Use a stronger cloud model for architecture, concurrency, security, review, and other correctness-sensitive work.
- Use local models only where results are likely equivalent and the verification path is strong.

## Core priorities

1. Correctness before speed.
2. Preserve buildability and testability after every change.
3. Prefer small, reviewable changes over broad rewrites.
4. Keep architecture explicit. Do not hide complexity behind clever abstractions.
5. Verify assumptions against code, tests, docs, or tooling output. Do not guess.

## Platform and stack defaults

[PLATFORM_DEFAULTS — fill in per project type]

## [CONDITIONAL] iOS 26 / Xcode 26.3 platform features

- **Liquid Glass** is the current iOS 26 / macOS 26 design language for materials and visual effects. Use `.glassEffect()` and related modifiers rather than custom `Material` or `UIVisualEffectView` implementations.
- **FoundationModels** is Apple's on-device LLM framework (iOS 26+). Evaluate before reaching for third-party ML inference.
- **Availability guards required.** Liquid Glass and FoundationModels require iOS 26+ / macOS 26+. Wrap in `#available(iOS 26, *)` / `#available(macOS 26, *)` guards if the deployment target is below iOS 26 / macOS 26.
- **Check Apple frameworks before third-party packages** for any new capability.
- For implementation details on any iOS 26 API, the `docs-researcher` agent reads directly from the Xcode documentation bundle at `$XCODE_APP/Contents/PlugIns/IDEIntelligenceChat.framework/Versions/A/Resources/AdditionalDocumentation/` (where `$XCODE_APP` defaults to `/Applications/Xcode.app` — override in `.claude/settings.json` env block if Xcode is installed elsewhere). If the path does not exist, fall back to web search.

## Architecture — universal layer discipline

These rules apply regardless of which architecture pattern this project uses.

- Choose one primary architecture pattern per app target before writing production code. **Document the choice and rationale in `ARCHITECTURE.md` before implementation begins.**
- Once chosen, apply the pattern consistently within its target. Any seam between two different patterns must be documented and justified.
- Separate presentation, domain, and data/transport layers into distinct types, files, or modules. No layer may reach past its immediate neighbor (presentation → domain → data; never presentation → data directly).
- Domain layer has zero import dependencies on UIKit, AppKit, SwiftUI, CoreData, SwiftData, gRPC, grpcio, or any persistence or networking framework.
- Generated Protobuf and gRPC types are transport types. They live in the data layer only. They must never appear in domain-layer type signatures or in presentation/view-model types.
- Every cross-layer dependency is expressed as an interface or protocol abstraction. Concrete implementations are injected; they are never instantiated inline by the consuming layer.
- Shared mutable state declares its owner type, owning actor or thread, lifecycle (who creates it, who destroys it), and mutation contract at the definition site. Undocumented shared mutable state is a defect.
- Services are stateless by default. Stateful services explicitly document their state variables, threading guarantees, and invalidation policy.
- Navigation logic lives outside view and view-model types. Use Coordinator, NavigationStack with a typed path, or a Router depending on the chosen pattern.

## [CONDITIONAL] Architecture rules — platform-specific

[PLATFORM_ARCHITECTURE — fill in from loaded skills]

## [CONDITIONAL] Language-specific coding rules

[LANGUAGE_RULES — fill in from loaded skills]

## [CONDITIONAL] gRPC and Proto3 rules

[GRPC_RULES — fill in from grpc-patterns skill, or delete section]

## Security

- Never hardcode secrets, API keys, tokens, or certificates in source code or config files committed to git.
- Validate all data received from the network before using it in domain logic or UI.
- TLS required for all gRPC connections. Do not disable certificate validation outside development.

[PLATFORM_SECURITY — fill in from security-patterns skill]

## Liskov Substitution Principle

- Every interface or protocol method must have a meaningful implementation in every implementing type. Silent no-ops and unconditional "not supported" throws that are not gated by capability checks are violations.
- No domain or presentation layer code may branch on the concrete type behind an abstract type reference. Use capability flags or feature checks for all implementation differences.
- No concrete data-layer type may be referenced by name in domain or presentation code. Only abstract types and domain model types cross layer boundaries.
- When adding a new interface or protocol, verify implementation correctness across all implementing types before committing.

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
and queryable. The specific language mechanism varies (compile-time or
runtime conformance checks, structural subtyping, flag values, enum
sets, etc.), but the design intent is consistent across any typed
system.

**Relationship to LSP.** LSP is a required coding practice — every
method declared in an interface must have a meaningful implementation
in every conforming type. The capabilities pattern is a recommended
best practice — an architectural tool for making supported behaviors
explicit and queryable. Neither is a prerequisite nor the motivation
for the other; they work well together when both are present. If the
capabilities pattern does not fit the project's architecture or the
developer opts out, that is valid.

## Dependency intake policy

Before adding any third-party framework or API:

1. Check whether platform frameworks already solve the need well enough.
2. Prefer the project's standard package manager with active maintenance, clear licensing, and recent activity.
3. Evaluate cross-platform impact, security risk, binary size, and lock-in.
4. Record why the dependency is needed, what alternatives were rejected, and the exit plan if the dependency becomes stale.
5. Do not add a dependency when a local wrapper around platform APIs is simpler and safer.

## Testing expectations

- Add or update tests with every non-trivial change.
- Use unit tests for domain logic and state transitions.
- Use integration tests for storage, networking adapters, and module seams.
- Use protocol-based test doubles for service stubs. Never hit real endpoints in unit or integration tests.

[PLATFORM_TESTING — fill in from loaded skills]

## Refactoring policy

- Do not mix unrelated refactors into feature work.
- Preserve external behavior unless the task explicitly changes behavior.
- When touching legacy code, improve naming, seams, and tests before broad rewrites.
- Prefer deleting dead code over preserving speculative abstractions.

## Skill loading

Agent prompts specify which skills to load. Skills are located in
`.claude/skills/<name>/SKILL.md`. The PM chat selects skills based on
`PLATFORM-SKILLS.md` — the skill-selection matrix for this project.

Skill selection follows a 5-dimension model: D1 (runtime / OS substrate),
D2 (cross-platform languages), D3 (component role / app-layer),
D4 (communication protocols), and D5 (deployment surface).
Skills load through three orthogonal mechanisms: Tier 0 base skills
(loaded for every project, every agent), intersection-cell skills (loaded
when specific D1–D5 cells apply), and trigger-loaded skills (loaded by
agent role rather than project shape).
See `docs/pack/PLATFORM-SKILLS.md` for the authoritative D1–D5 tables,
the Tier 0 base list, the sparse intersection table, and the
trigger-loaded list.

**Tier 0 installation note.** Skills at `project-template/skills/` in the
pack repo are auto-distributed to all three client CLI skill directories
(`.claude/skills/`, `.codex/skills/`, `.agents/skills/`) via `stage_s4_skills()`
at install time; the Tier 0 base list is then loaded by every agent for every
project. See `scripts/init-project.sh` `stage_s4_skills()` and the
`boundary-investigation` Tier 0 skill for the canonical reference.

**Active skills:** [PM chat writes this line during project kickoff, listing
the skills derived from PLATFORM-SKILLS.md for this project's type. Example:
`swift-best-practices, apple-architecture-core, macos-architecture`.
Update this line whenever skills are added or removed mid-project.]

The PM chat checks this list at every phase gate (METHODOLOGY.md Procedure 1).
If an upcoming phase references a technology not covered by the active skills,
the PM chat flags the gap before generating any prompt. Skills are added or
removed by updating this line and the project description above — then committing.

Project-specific (custom) skills use the `x-` prefix and live alongside
pack skills in `.claude/skills/x-<name>/`, `.codex/skills/x-<name>/`, and
`.agents/skills/x-<name>/`. Pack-supplied skills never begin with `x-`.
See `docs/pack/INSTALL-PROCEDURES.md` § "Project file conventions in
pack-controlled directories" for the full convention and Procedure 5.2
for the creation workflow.

## Document locations

Project documentation is organized into three directories under `docs/`.
All filenames are unique — reference them by name; use these paths to locate them.

The Source column indicates that files in each directory are flat-file
(source of truth in the working tree). Flat-file per-entry is the sole
supported mode, so all rows read `flat`. `pm-startup` Step 2 reads this
column.

| Directory | Contents | Updated by | Source |
|---|---|---|---|
| `docs/pack/` | `METHODOLOGY.md`, `INSTALL-PROCEDURES.md`, `prompts/`, `PM-CHAT.md`, `PLATFORM-SKILLS.md`, `PACK-FEEDBACK.md` | Pack version updates only (except PACK-FEEDBACK.md — PM chat appends during project) | flat |
| `docs/project/` | `ARCHITECTURE.md`, `IMPLEMENTATION-PLAN.md`, `BACKLOG.md`, `STATUS.md`, `CHANGELOG.md` (regenerated mirrors for BACKLOG/IMPLEMENTATION-PLAN/CHANGELOG — per-entry source in subdirs) | PM chat and developer during active development | flat |
| `docs/reference/` | Project-specific user-facing documentation (how-to guides, API references) | Developer as needed | flat |

Root-level files: `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `README.md`, `agent-run.sh`.

**Per-entry source-of-truth trees (v11.0).** Project streams under
`docs/project/backlog/`, `docs/project/implementation-plan/`, and
`docs/project/changelog/` are per-entry source-of-truth trees in
flat-file mode; read each `<stream>/_rules.md` for the per-stream
contract before any per-entry edit. The monolithic `BACKLOG.md`,
`IMPLEMENTATION-PLAN.md`, and `CHANGELOG.md` files in `docs/project/`
are regenerated mirrors — read-stable but never source of truth.
Flat-file per-entry is the sole supported mode.

**Operating docs carry NO history, NO deferred-feature mentions; stay
terse + structured.** An operating doc (a doc an agent or chat EXECUTES as
live instruction — these rules, agent/skill definitions, prompts,
write-contracts) carries (a) ZERO historical/audit-trail text (dated
notes, "X did Y" past-action narration, provenance/"carried from" notes,
incident or commit-SHA refs); (b) ZERO description of a DEFERRED,
unimplemented, or off-by-default feature — even to say it is deferred
(state only what currently exists and operates; the mention is re-added
when the feature ships); and (c) is kept terse + structured (no
mega-bullet run-ons, prose-that-should-be-a-table, or padding). LIVE
forward-pointers to CURRENT in-flight work KEEP. History and roadmap
belong in the project streams (`docs/project/backlog/` and
`docs/project/changelog/`) and in IMPL reports — never copied into an
operating doc.

## Scripts

`agent-run.sh` lives in the **project root** and is the standard way to launch any agent.
The `scripts/` directory contains build, test, and validation scripts. **Copy both from the
pack template and make executable before first use** (`chmod +x agent-run.sh scripts/*.sh`).

| Script | Location | When to run | Who calls it |
|---|---|---|---|
| `agent-run.sh` | Project root | To launch any agent — run `./agent-run.sh --help` | Human only |
| `bootstrap.sh` | `scripts/` | Once on first checkout or new machine — detects languages and calls the right bootstrap-\<lang\>.sh | Human |
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
| `agent-post-edit-check.sh` | `scripts/` | **Never call manually** — fires automatically via Claude Code PostToolUse hook and Codex post_edit_command after every agent file edit | Automatic hook |

**Required first-time setup (Swift projects only):** Open `scripts/validate-swift.sh`
and `scripts/test-swift.sh` and fill in the scheme and destination variables. Until set,
`xcodebuild` steps are skipped and the scripts only run `swift build` / `swift test`.
Non-Swift projects can ignore this paragraph.

**Wrapper detection:** Wrapper scripts (`format.sh`, `validate.sh`, `bootstrap.sh`, `test.sh`)
detect which languages are present via marker files (`Package.swift` → Swift, `pyproject.toml` →
Python, `proto/` → protobuf) and call only the relevant language-specific scripts.

**Note:** `format.sh` is manual-only — it is not wired into the automatic post-edit hook.
Run it explicitly before committing or ask `repo-ops` to run it.

## Build and repo hygiene

- Do not commit secrets, generated code, or machine-specific config.
- Do not commit generated Protobuf or gRPC files. Regenerate via `proto-gen.sh`.
- Prefer repo-local scripts over undocumented manual steps.
- Document any new setup requirement in README.md or docs/.
- **At the end of every implementation phase**, include a **"Proposed CHANGELOG entry"**
  section in your completion report, formatted exactly as it would appear in `CHANGELOG.md`:
  dated header, summary paragraph, itemised task list, files created/modified, and final
  test count. Do not write to `CHANGELOG.md` or any other `.md` file in the project root —
  the PM chat applies the entry after reviewer approval.

## Git workflow

- Make commits small and coherent.
- Include tests when behavior changes.
- Separate mechanical formatting from semantic changes when practical.
- Surface risky migrations early.

## Deferral comments and BACKLOG hygiene

Three comment types are recognized for deferring work. Use the marker for the
language you are writing (`//` for Swift/C/C++/Objective-C, `#` for Python):

```
// TODO(scope): TD-TBD — Short title
// KNOWN GAP(severity): TD-TBD — Short title
// VERIFY(source): TD-TBD — Short title
```

**Valid scope values for TODO:** `phase-N`, `dependency`, `feature`, `perf`, `version`
**Valid severity values for KNOWN GAP:**
- `critical` — must eventually be addressed without exception
- `functional` — should be addressed; feature is incomplete without it
- `polish` — may be skipped; improves experience but does not affect correctness
**Source for VERIFY:** name the external source (e.g. `apple-docs`, `schwab-api`)

**Rules — read carefully:**
- Always write `TD-TBD` — never a real TD number. The PM chat assigns numbers after review.
- Report every deferral comment added in the "Deferred items" section of the completion report.
- Do not write to `BACKLOG.md`, `CHANGELOG.md`, `STATUS.md`, `PACK-FEEDBACK.md`, or
  any other `.md` file in the project root — these are exclusively the PM chat's
  responsibility. Do not resolve or modify existing BACKLOG entries. Never write
  to `PACK-FEEDBACK.md` under any circumstance — it is the PM chat's upstream
  feedback log for the AI Agent Config Pack itself.
- Work that could be completed within the current phase scope is NOT a TODO — it is
  an incomplete task. The reviewer will flag it as an implementation plan compliance failure.
- Never use plain English deferral comments (`// Fix later`, `// Confirm this`, etc.).
  Use the typed format above or do not leave a comment.
- When citing a code location in a report, use the symbol name not the line number.
  Line numbers drift with every edit; symbol names are stable.

## [CONDITIONAL] Anti-patterns — never introduce these

- Massive view controllers or God ViewModels accumulating unrelated logic.
- Calling generated gRPC stubs directly from ViewModels or Views.
- Putting auth tokens or credentials in Protobuf message fields.
- Singleton sprawl for services that could be injected.
- Mutable global state that is not documented as such.
- Domain types appearing in data-layer or transport-layer signatures.
- Stringly-typed identifiers or state machines.
- Magic duration literals for gRPC deadlines — use named constants.
- Editing generated Protobuf or gRPC code by hand.
- Branching on concrete types to discover what an abstraction supports, instead of querying a capability value or interface.

[PLATFORM_ANTIPATTERNS — fill in from loaded skills]

## Project memory

These rules govern every agent invocation in this project. Each
agent's full operating rules (Permission profile, Output policy,
Hard rules) live in its own definition file under
`.claude/agents/<agent>.md`, `.codex/agents/<agent>.toml`, and the
Antigravity plugin bundle `.agents-plugin/optiquity-agents/agents/<agent>.md`.
The agent file is authoritative for
what that agent may and must do; this section carries only the
universal collaboration rules that apply project-wide regardless
of agent role.

- **Trinity rule.** When modifying `CLAUDE.md`, `AGENTS.md`, or
  `GEMINI.md` at the project root, the same change applies to all
  three in the same set of edits. Symmetry is the default;
  asymmetry requires justification as provably tool-specific.
- **No destructive operations without explicit approval.** Before
  any `git rm`, `rm -rf`, file deletion, overwrite, or any
  working-tree- or ref-mutating git verb — `git reset` (any mode),
  `git restore`, `git checkout` (path checkout or branch switch),
  `git clean`, `git stash`, `git merge`, `git rebase`, or
  `git worktree` (add/remove/prune) — on a file with uncommitted
  agent work, state exactly what will be destroyed and wait for
  explicit approval, even when the overall task is approved. The
  guiding principle: read-only git verbs are allowed; any git verb
  that changes working-tree, index, ref, or config state is
  destructive and needs approval, including but not limited to the
  ones enumerated here. (Agents go further — an agent runs NO
  state-changing git verb at all; see the agent's own definition
  file.)
- **PM chat does not architect.** Architecture, planning,
  implementation, and review work goes to the corresponding agent.
  The full pack agent roster is at `docs/pack/PM-CHAT.md` §
  Pack agent roster — that section is the project-side SSOT; do
  not infer the roster from any other source. The PM chat handles
  BACKLOG, STATUS, CHANGELOG, routing, approvals, and prompt
  construction — not the work the agents do.
- **Project SSOT-first.** When making any change to a project file
  (architecture, BACKLOG, agent prompt, skill content, etc.),
  investigate the existing project SSOT for that concept FIRST. Do
  not default to importing rules, file references, or orchestrator
  roles from external sources (the AI Agent Config Pack repo itself,
  third-party templates, other projects). Pack-shipped files
  installed in this project (e.g., `docs/pack/PM-CHAT.md`,
  `docs/pack/PLATFORM-SKILLS.md`, `docs/pack/PACK-FEEDBACK.md`,
  the project trinity at the project root) are part of the project
  SSOT and may be referenced. Files at the pack repo
  <!-- DENY-LIST-CONTENT-START -->
  (PACK-AGENTS.md,
  PACK-CHAT.md, pack-* agent prompts, pack-repo `maintenance-docs/`,
  pack-repo `pack-ops/` — any file under `pack-ops/`, including
  BOUNDARY-DEFINITION.md, BACKLOG.md, CHANGELOG.md, etc.)
  <!-- DENY-LIST-CONTENT-END -->
  are NOT
  part of the project SSOT and must not be referenced from project
  files — the pack repo is not present at this client install. See
  the `boundary-investigation` skill for the SSOT-investigation
  methodology.
- **Reconciliation-instance independence.** A reconciliation pass
  (resolving an adversarial review before the work advances) uses a
  FRESH instance — never the original author nor the adversarial
  reviewer. Applies to every project agent role (architect, planner,
  coder, reviewer, auditor, repo-ops, tester, grpc-schema, and the
  rest) EXCEPT `docs-researcher` (factual inventory — reuse OK).
  Carve-outs: the developer explicitly asks to re-engage an existing
  agent (on Claude Code via `SendMessage`; on Codex / Antigravity via
  the platform re-engage path), or a per-case architect-challenge
  reason.

## Phase routing — default agent assignments

All three tools (Claude Code, Codex, Antigravity CLI) can execute any phase.
The defaults below identify the better system for each phase. Override
when task characteristics favor a different tool.

| Phase | Default | Agent | Key reason |
|---|---|---|---|
| Architecture / design | **Claude Code** | architect | Multi-file context, extended reasoning |
| API and schema design | **Claude Code** | grpc-schema | Schema tools, buf integration |
| Planning / task breakdown | **Claude Code** | planner | Tiebreaker — all systems comparable |
| Dependency evaluation | **Claude Code** | docs-researcher | Web search, nuanced tradeoff analysis |
| Implementation | **Codex** | coder | Workspace-write sandbox, strong code generation |
| Code review | **Claude Code** | reviewer | Deep multi-file analysis, Bash diagnostics |
| Testing | **Codex** | tester | Pattern generation, approval flow for new files |
| Debugging | **Claude Code** | coder | Multi-step reasoning, Bash for live diagnostics |
| Refactoring | **Codex** | coder | Mechanical changes in workspace-write sandbox |
| Documentation | **Claude Code** | docs-researcher | Multi-file context aids consistency |
| Repo operations | **Codex** | repo-ops | Workspace-write sandbox, scripting strength |
| Local validation | **Codex** | repo-ops | Workspace-write sandbox; can execute scripts |

To invoke any agent: `./agent-run.sh <cli> --agent <name>` (see `./agent-run.sh --help`).
For Antigravity CLI (`agy`), `agent-run.sh` resolves `--agent` to the role
defined in the plugin bundle (`.agents-plugin/optiquity-agents/agents/<name>.md`)
and launches it via Antigravity's subagent mechanism — the same command format
works for all three CLIs. (Re-verify the Antigravity agent-invocation mechanism
against `antigravity.google/docs/subagents` before relying on it; the subagent
API is in preview.)

### Custom agents

Project-specific agents created via Procedure 5 (see
`docs/pack/INSTALL-PROCEDURES.md`). See
`docs/pack/PLATFORM-SKILLS.md` § "Custom agents" for the canonical list
and full skill assignments. All custom agent names begin with `x-`.

| Phase | Agent | Key reason |
|---|---|---|
| (Developer / PM chat adds rows per project during Procedure 5) |  |  |

## Agent behavior

When acting in this repo:
- Plan first for non-trivial work.
- Call out uncertainty explicitly.
- Do not invent APIs, framework behavior, or build flags.
- Read existing code before introducing new patterns.
- Match local style when it does not violate these rules.
- Prefer changing the smallest correct surface area.

## Project addenda

<!-- Project addenda go here. Project-original H2 sections that don't
fit into pack-defined sections above land under this heading when you
reconcile your customizations during a v10 → v11 migration. See
MIGRATION-v10-to-v11.md § "Step 2 — Review the migration report" for
the reconciliation workflow. New projects start with this H2 empty.
The marker is preserved across pack upgrades. -->
