# AGENTS.md

<!--
HOW TO USE THIS TEMPLATE

This is the Codex CLI context file for your project. It is loaded automatically
by Codex CLI at session start.

Fill in [PROJECT_NAME], [PLATFORM_TARGETS], and [TRANSPORT] during project setup.
Fill in or remove conditional sections marked with [CONDITIONAL].
Remove this comment block after filling in the placeholders.

This file is the Codex equivalent of CLAUDE.md and GEMINI.md. All three files
should express the same project rules — only tool-specific operating notes differ.
-->

---
*Copied from: project-template/AGENTS.md — AI Agent Config Pack v9*
*Fill in placeholders and remove this block.*
---

**[PROJECT_NAME]** targets [PLATFORM_TARGETS].
Transport: [TRANSPORT] (e.g., gRPC + Proto3 for first-party; REST for third-party).

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

## Platform defaults

<!--
Fill in platform-specific defaults. See CLAUDE.md for detailed examples.
-->

[PLATFORM_DEFAULTS — fill in per project type]

## [CONDITIONAL] iOS 26 / Xcode 26.3 platform features

<!--
Include this section only for projects targeting iOS 26+ / macOS 26+.
Delete the entire section for Python-only or non-Apple projects.
-->

- **Liquid Glass** is the current iOS 26 / macOS 26 design language. Use `.glassEffect()` and related modifiers.
- **FoundationModels** is Apple's on-device LLM framework (iOS 26+). Evaluate before third-party ML inference.
- **Availability guards required.** Wrap in `#available(iOS 26, *)` / `#available(macOS 26, *)` if deployment target is below iOS 26.
- **Check Apple frameworks before third-party packages** for any new capability.
- For iOS 26 API details, read directly from the Xcode documentation bundle at `/Applications/Xcode.app/Contents/PlugIns/IDEIntelligenceChat.framework/Versions/A/Resources/AdditionalDocumentation/`. If the path does not exist, fall back to web search.

## Architecture — universal layer discipline

These rules apply regardless of which architecture pattern this project uses.

- Choose one primary architecture pattern before writing production code. **Document in `ARCHITECTURE.md` before implementation begins.**
- Separate presentation, domain, and data/transport layers. No layer reaches past its immediate neighbor.
- Domain layer has zero framework imports (no UIKit, AppKit, SwiftUI, gRPC, grpcio).
- Generated Protobuf/gRPC types live in the data layer only — never in domain or presentation signatures.
- Cross-layer dependencies are protocol abstractions. Concrete types are injected.
- Shared mutable state documents its owner, lifecycle, and mutation contract. Undocumented shared mutable state is a defect.
- Services are stateless by default. Stateful services document state, threading, and invalidation.

## [CONDITIONAL] Design and coding rules

<!--
Add architecture, language, and protocol rules from your project's skills.
See CLAUDE.md for the full breakdown of conditional sections:
- Platform architecture rules
- Language-specific coding rules
- gRPC/protocol rules
- Security rules
- Anti-patterns

AGENTS.md can be more concise than CLAUDE.md — include the rules but
skip lengthy explanatory comments. The loaded skills have the full detail.
-->

[PLATFORM_RULES — fill in from loaded skills]

## Liskov Substitution Principle

- Every interface or protocol method has a meaningful implementation in every implementing type. Silent no-ops and unconditional "not supported" throws not gated by capability checks are violations.
- No code branches on the concrete type behind an abstract type reference.
- No concrete data-layer type is referenced by name in domain or presentation code.

## Dependency intake

1. Check platform frameworks first.
2. Prefer actively maintained packages with clear licensing.
3. Evaluate security, size, lock-in.
4. Record rationale, alternatives, and exit plan.

## Testing policy

- Add or update tests for non-trivial changes.
- Use protocol-based test doubles. Never hit real endpoints in unit or integration tests.
- Prefer unit tests for domain logic. Integration tests at module seams.

<!--
Add platform-specific testing rules from loaded skills.
-->

[PLATFORM_TESTING — fill in from loaded skills]

## Refactoring policy

- Do not mix unrelated refactors into feature work.
- Preserve external behavior unless the task explicitly changes behavior.
- When touching legacy code, improve naming, seams, and tests before broad rewrites.
- Prefer deleting dead code over preserving speculative abstractions.

## Git and review policy

- Keep commits coherent.
- Separate formatting from behavior changes.
- Preserve existing behavior during refactors unless the task says otherwise.
- Do not commit generated Protobuf/gRPC files. Regenerate via `proto-gen.sh`.

## Skill loading

Agent prompts specify which skills to load. Skills are located in
`.codex/skills/<name>/SKILL.md`. The PM chat selects skills based on
`PLATFORM-SKILLS.md` — the skill-selection matrix for this project.

**Active skills:** [PM chat writes this line during project kickoff, listing
the skills derived from PLATFORM-SKILLS.md for this project's type. Example:
`swift-best-practices, apple-architecture-core, macos-architecture`.
Update this line whenever skills are added or removed mid-project.]

The PM chat checks this list at every phase gate (METHODOLOGY.md Procedure 1).
If an upcoming phase references a technology not covered by the active skills,
the PM chat flags the gap before generating any prompt. Skills are added or
removed by updating this line and the project description above — then committing.

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
| `proto-gen.sh` | `scripts/` | After editing any `.proto` file — runs buf lint then buf generate | Human or `grpc-schema` agent |
| `agent-post-edit-check.sh` | `scripts/` | **Never call manually** — fires via Codex post_edit_command and Claude Code PostToolUse hook | Automatic hook |

Set `XCODE_SCHEME` and `XCODE_DESTINATION` in `validate.sh` and `test.sh` before first use —
without them, xcodebuild steps are skipped silently (a warning is printed).

## BACKLOG permissions and deferral comments

**What you may do:** Add typed deferral comments in code when you encounter work that
cannot be completed within the current phase scope. Report them in your completion report.

**What you may not do:** Write to `BACKLOG.md`, `CHANGELOG.md`, `STATUS.md`,
`PACK-FEEDBACK.md`, or any other `.md` file in the project root — these are
exclusively the PM chat's responsibility. Resolve or modify existing BACKLOG
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

**BACKLOG write permissions by agent:**

| Agent | May do | May not do |
|---|---|---|
| `coder` | Write TD-TBD comments; report in completion report | Write to BACKLOG.md |
| `reviewer` | Read only | Write anything |
| `docs-researcher` | Read only | Write anything |
| `repo-ops` | Read only | Write anything |

## [CONDITIONAL] Anti-patterns — never introduce

<!--
Include universal anti-patterns and add platform-specific ones from skills.
See CLAUDE.md for the full list with examples.
-->

- Calling gRPC stubs directly from ViewModels or Views.
- Auth tokens in Protobuf message fields.
- Singleton sprawl for injectable services.
- Mutable global state undocumented as such.
- Domain types in data-layer or transport-layer signatures.
- Magic duration literals for gRPC deadlines.
- Editing generated Protobuf or gRPC code by hand.

[PLATFORM_ANTIPATTERNS — fill in from loaded skills]

## Agent behavior

- Plan first for non-trivial work.
- Read existing code before adding new abstractions.
- Do not invent APIs, framework behavior, or build flags.
- Prefer the smallest correct change.
- State uncertainty explicitly.
- When using a local model, avoid high-risk changes unless a stronger model has reviewed the plan.

## Phase routing — default agent assignments

Both Codex and Claude Code can execute any engineering phase in this repo.
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

To invoke any agent: `./agent-run.sh <cli> --agent <name>` (see `./agent-run.sh --help`)
