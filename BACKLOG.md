# Backlog

All planned improvements to the AI Agent Config Pack are tracked here.
Items use BD-NNN identifiers (pack backlog) rather than TD-NNN (project backlog).
Format follows the standard BACKLOG item format from METHODOLOGY.md Part 7.

---

## How to use this file

- Reference items in commit messages: `feat: v9 — BD-020 description`
- When an item is resolved, set Status: Resolved with the commit hash and date
- To cancel or deprecate an item: set Status to Cancelled or Deprecated, add a
  Resolution field with date, disposition (cancelled|deprecated), and brief rationale.
  Then review all items that listed this item as a blocker — they require human
  judgment, not automatic unblocking
- Items deferred to a future version: set Blockers to the target version
- New items get the next available BD-NNN number
- This file ships in the repo so agents can read it and understand current scope

---

## Active — v9 Scope

**BD-020 — C++ server support analysis**
Type: TODO(version)
Status: Open
Blockers:
  - No concrete C++ project need has arisen
  - BD-024 unified template redesign must be completed first — analysis outcome
    determines skills needed, not a new template directory
Unblocks: None
File/Symbol: n/a — new file `maintenance-docs/CPP-SERVER-ANALYSIS.md` to be created
Description: C++ is a common choice for high-performance gRPC servers and
  systems-level services. Under the unified template model (BD-024), this analysis
  determines what skills are needed rather than whether a new template directory
  is required. The analysis document should cover: C++ gRPC library choices
  (grpc++ official library), build system options (CMake, Bazel, Makefile),
  what a `cpp-server-architecture` skill would need to cover, what a
  `cpp-language` skill would need to cover (if not already created by BD-024),
  toolchain differences from Python/Swift, and whether any existing pack files
  apply unchanged.
Context: Analysis only — no implementation until a concrete project need arises.
  Original framing assumed a new template directory; updated April 2026 to reflect
  the unified template model from BD-024. Outcome is skill files, not a template.
Resolved: n/a

---

**BD-021 — Redesign Apple platform architecture skills (three-tier)**
Type: TODO(version)
Status: Deprecated
Blockers:
  - BD-022 c-language skill must exist first (shared dependency between Apple and C templates)
  - v9 planning conversation needed to confirm skill boundaries
Unblocks: None
File/Symbol: n/a — modifications across apple-app and monorepo template files
Description: The current `ios-architecture` skill applies to all Apple targets but macOS
  and iOS are not a superset/subset of each other — they are siblings with significant
  platform-specific differences. A single combined skill either includes irrelevant checklist
  items or misses platform-specific ones. Universal apps complicate this further.

  Proposed three-tier design:

  1. `apple-architecture-core` skill (new) — patterns shared across all Apple platforms:
     SwiftUI-first design, protocol abstractions at layer boundaries, immutability defaults,
     actor isolation, typed IDs, LSP compliance, SPM module structure. ~60% of current
     `ios-architecture` skill content.

  2. `ios-architecture` skill (refocus existing) — iOS/iPadOS-specific: scene lifecycle,
     UIKit interop justification, background task design, App Store/extension boundaries,
     touch-first interaction model. Remove overlap with core.

  3. `macos-architecture` skill (new) — macOS-specific: NSDocument-based architecture,
     multiple NSWindow management, AppDelegate lifecycle and Dock behavior, menu bar ownership
     and command validation, AppKit interop patterns, Services/AppleScript/Shortcuts
     integration, sandboxed file access model, floating panels and inspector windows.

  For universal apps: `apple-architect` agent uses all three skills — core plus both
  platform skills. Agent description updated to specify the combination per project target type.

  For future platforms (watchOS, visionOS, tvOS): same pattern — platform-specific skill
  alongside core. Not in scope for this item.

  Also required: Update `apple-architect` agent description and phase routing tables in
  CLAUDE.md and AGENTS.md to reference the correct skill combination per project type.
Context: macOS and iOS are siblings, not superset/subset. A single combined skill
  produces irrelevant checklist items for platform-specific projects. Universal apps
  need all three skills; single-platform projects need core + platform skill only.
Resolution: April 2026, deprecated — superseded by BD-024 (unified template and
  platform skills redesign). The three-tier skill design (apple-architecture-core,
  ios-architecture, macos-architecture) is preserved and becomes part of BD-024's
  skill library. The template-directory framing is dropped.

---

**BD-022 — C project template and c-language skill**
Type: TODO(version)
Status: Deprecated
Blockers:
  - v9 planning conversation needed to confirm build system and test framework choices
Unblocks: BD-021 (c-language skill is a shared dependency)
File/Symbol: n/a — new `c-project-template/` directory; new `c-language` skill file
Description: Standalone C projects (command-line tools initially; embedded code and libraries
  in scope for later iterations) currently have no pack support. A lightweight template is
  needed with a minimal agent set and simple tooling choices.

  Template scope — v9 target (command-line tools):
  - Agents: `architect`, `planner`, `coder`, `reviewer` — no grpc-schema, no docs-researcher,
    no Python-specific agents
  - Build system: Makefile (simple, universally available, no dependencies)
  - Testing framework: one lightweight C test framework (e.g. Unity or Check — decide at
    implementation time based on simplicity and macOS/Linux compatibility)
  - Static analysis: `clang-tidy` or `cppcheck` (decide at implementation time)
  - Scripts: `bootstrap.sh`, `build.sh`, `test.sh`, `format.sh` (clang-format), `validate.sh`
  - CLAUDE.md and AGENTS.md: C-specific rules (memory management, no hidden allocations,
    explicit ownership, no undefined behavior, const correctness, header hygiene)
  - No gRPC, no proto scaffold, no Python tooling

  Later iterations (deferred):
  - Embedded code: cross-compiler support, hardware abstraction layer patterns, interrupt safety
  - Libraries: shared library vs static library conventions, versioned ABI, pkg-config

  c-language skill (also needed for BD-023 — Apple mixed-language projects):
  A `c-language` skill for use in `coder`, `reviewer`, and `architect` agents across any
  template where C code may appear. Covers: memory ownership and lifecycle, pointer safety,
  buffer handling, null termination discipline, const correctness, header include guards,
  function naming conventions, interop with Swift (bridging headers), interop with Python
  (ctypes/cffi/Cython), and common C anti-patterns to avoid.
Context: SPM vs Makefile was discussed — Makefile chosen for simplicity and zero dependencies.
  c-language skill is created here and shared with BD-023 to avoid duplication.
Resolution: April 2026, deprecated — superseded by BD-024 (unified template and
  platform skills redesign). The c-project-template directory is dropped; a C project
  will use the single unified template with c-language skill loaded. The c-language
  skill content is preserved and becomes part of BD-024's skill library.

---

**BD-023 — Mixed-language skills for Apple projects (Objective-C, C, C++, graphics)**
Type: TODO(version)
Status: Deprecated
Blockers:
  - BD-022 must be completed first — c-language skill is shared between C template and Apple projects
Unblocks: None
File/Symbol: n/a — new skill files for use in apple-app and monorepo template agents
Description: Apple projects may contain Objective-C (legacy code), C (performance routines,
  third-party library bridges), or C++ (performance-critical code, graphics). New projects
  will not use Objective-C, but old projects may require modifications. New projects may add
  C or C++ for performance or graphics. Agents need targeted skills for each case — not a
  combined skill, since the contexts and patterns differ significantly.

  Skills to create:

  `objc-language` skill — for `coder` and `reviewer` agents:
  Read/modify legacy Objective-C code in Swift-first projects. Covers: ARC memory management,
  nullability annotations (`_Nullable`, `_Nonnull`), bridging header patterns, NS_SWIFT_NAME
  and NS_REFINED_FOR_SWIFT, @objc attribute usage, property declaration patterns, avoid writing
  new Objective-C unless there is no Swift alternative. Writing new Objective-C is a last resort
  only — document why no Swift alternative exists. No Objective-C++ (`.mm` files) in scope.

  `c-language` skill — shared with BD-022:
  See BD-022. Same skill, used here when C appears in Apple projects: wrapping third-party C
  libraries via bridging headers, writing performance-critical routines called from Swift via
  a C shim, C interop patterns. Covers ownership, pointer safety, const correctness, and
  Swift-C bridging conventions.

  `cpp-language` skill — for `coder` and `reviewer` agents:
  C++ in Apple projects for performance-critical code or graphics work. Covers: RAII and
  ownership (no raw `new`/`delete` in modern C++), `std::unique_ptr` and `std::shared_ptr`
  patterns, Swift-C++ interoperability (Swift 5.9+ direct C++ interop), header organization
  (`.hpp`/`.cpp` split), avoiding exceptions in performance paths, const correctness, rule of
  five, and common C++ anti-patterns. Does not cover Objective-C++ (`.mm`) — that is a
  separate concern handled at the architecture level if ever needed.

  Graphics engine skills (separate skills, each focused on one engine/framework):
  These are distinct enough from general C/C++ to warrant their own skills. Each engine has
  its own patterns, asset pipeline, and integration model. To be created when a concrete
  project need arises:
  - `metal-cpp-language` skill — Metal C++ API patterns (distinct from Swift Metal)
  - `unity-cpp-language` skill — Unity C++ native plugin patterns
  - `unreal-cpp-language` skill — Unreal Engine C++ patterns (UObject, UFUNCTION, etc.)
  Note: Metal via Swift bridge already works with existing Apple skills — no new skill
  needed for Swift Metal usage.

  Agent integration:
  These are skills used by existing agents, not new agents. The `apple-architect` agent
  (and future platform-specific variants per BD-021) would reference the appropriate skills
  when the project contains mixed-language code. The `coder` and `reviewer` agents include
  the skill when working on files of the relevant type.

  Objective-C template: Not planned. Objective-C support is skill-only. A full
  `objc-project-template` is out of scope unless a concrete project need arises.
Context: Skills-only approach chosen over a new template. Graphics engine skills deferred
  until a concrete project need arises — they are too engine-specific to define speculatively.
Resolution: April 2026, deprecated — superseded by BD-024 (unified template and
  platform skills redesign). The Apple-specific framing is dropped; all skills
  (objc-language, c-language, cpp-language, graphics engine skills) become part of
  the unified skill library available to any project. Skill content from this item
  is fully preserved in BD-024.

---

## Resolved — v8 (March 2026)

All BD-001 through BD-019 items resolved across Groups 1–6.

| Item | Description | Commit |
|---|---|---|
| BD-001 | Rename ios-architect → apple-architect | 08f7158 |
| BD-002 | Add post_edit_command to .codex/config.toml (all 3 templates) | 08f7158 |
| BD-003 | Add scripts setup and usage docs to CLAUDE.md, AGENTS.md, QUICKSTART.md | 9cd9a7f |
| BD-004 | Resolve format.sh hook discrepancy | 08f7158 |
| BD-005 | Add XCODE_SCHEME warnings to validate.sh, test.sh, agent-post-edit-check.sh | 08f7158 |
| BD-006 | Add python-architect agent + python-architecture skill (python-server, monorepo) | 61b3381 |
| BD-007 | New-project generation templates (SETUP_TEMPLATE.md, AGENT_KICKOFF_TEMPLATE.md) | 2fc4a0c |
| BD-008 | Add METHODOLOGY.md to all templates and supporting-docs | 2fc4a0c |
| BD-009 | Add PROMPT-TEMPLATES.md to supporting-docs (14 templates) | 2fc4a0c |
| BD-010 | Update QUICKSTART.md Steps 11–13 for PM chat and new-project workflow | 2fc4a0c |
| BD-011 | Add VS Code companion files in vscode-companion-templates/ | 61b3381 |
| BD-012 | Commit Methodology Guide v1 to maintenance-docs/origins/ | 2fc4a0c |
| BD-013 | Gemini CLI analysis document | 9a6ba5b |
| BD-014 | Android support analysis document | 9a6ba5b |
| BD-015 | Document SETUP.md/AGENT_KICKOFF.md generation workflow | 2fc4a0c |
| BD-016 | Merge OT content into apple-app CLAUDE.md/AGENTS.md | 9cd9a7f |
| BD-017 | Fix availability guard omission in iOS 26 platform features section | 08f7158 |
| BD-018 | v7→v8 migration guide | 9a6ba5b |
| BD-019 | Desktop Commander usage and PM chat scope limits (METHODOLOGY.md) | 2fc4a0c |

---

**BD-024 — Unified template and platform skills redesign**
Type: TODO(version)
Status: Open
Blockers:
  - v9 planning conversation needed to finalize skill boundaries and script strategy
Unblocks: BD-020 (C++ analysis outcome depends on unified model being settled)
File/Symbol: n/a — replaces three template directories with one; new skill library
Description: Replace the three template directories (apple-app-template,
  python-server-template, apple-app-plus-python-server-template) with a single
  unified template containing platform-agnostic agents and a composable skill
  library. The PM chat selects the appropriate skills per project at prompt
  generation time based on the project's platform profile in CLAUDE.md.

  **Motivation:** Adding any new platform (Android, Windows, C++ server, embedded)
  currently requires a new template directory with ~25 duplicated files. This is
  unsustainable. Under the unified model, adding a platform requires only new skill
  files and a documentation update — no new agents, no new template directories.

  **Agent changes:**
  - `apple-architect` and `python-architect` merge into a single `architect` agent
    with a platform-agnostic system prompt. Platform knowledge comes from skills.
  - All other agents (coder, reviewer, tester, docs-researcher, planner, repo-ops,
    grpc-schema) are already platform-agnostic — no changes required.
  - Agent files move from three template directories into one.

  **Skill library to create** (all skills are platform-agnostic and composable):
  - `swift-best-practices` — Swift language, concurrency, type system, Swift 6 rules
  - `apple-architecture-core` — patterns shared across all Apple platforms: SwiftUI,
    protocol abstractions, actor isolation, typed IDs, LSP compliance, SPM structure
  - `ios-architecture` — iOS/iPadOS-specific: scene lifecycle, UIKit interop,
    background tasks, App Store boundaries, touch-first interaction model
  - `macos-architecture` — macOS-specific: NSDocument, multiple NSWindow management,
    AppDelegate, menu bar, AppKit interop, sandbox, notarization, Services integration
  - `python-best-practices` — Python patterns, async, type hints, ruff/pyright rules
  - `grpc-patterns` — Protobuf schema design, gRPC service patterns, buf tooling
  - `c-language` — memory ownership, pointer safety, buffer handling, const
    correctness, header guards, Swift/Python interop (from BD-022)
  - `objc-language` — ARC, nullability annotations, bridging headers, NS_SWIFT_NAME,
    legacy code modification patterns (from BD-023)
  - `cpp-language` — RAII, smart pointers, Swift-C++ interop, header organization,
    rule of five, C++ anti-patterns (from BD-023)

  **Skill selection by project type** (PM chat uses this at prompt generation time):
  - macOS Swift app: swift-best-practices + apple-architecture-core + macos-architecture
  - iOS Swift app: swift-best-practices + apple-architecture-core + ios-architecture
  - Universal app: swift-best-practices + apple-architecture-core + ios-architecture
    + macos-architecture
  - Python gRPC server: python-best-practices + grpc-patterns
  - Swift app + Python runtime (e.g., embedded interpreter): swift-best-practices
    + macos-architecture + c-language (Python C API is the bridge)
  - Mixed-language Apple: add objc-language or cpp-language as needed

  **Scripts:** bootstrap.sh, validate.sh, format.sh require platform-aware logic or
  a lightweight generator that assembles the correct script content at project setup
  time based on answered platform questions. Strategy to be decided during v9 planning.

  **METHODOLOGY.md update required:** Add a skill-selection section describing how
  the PM chat determines which skills to load for a given project type, and where
  the project's platform profile is declared (CLAUDE.md).

  **Deferred to future items:**
  - Android, Windows, embedded platform skills — new skill files only when needed
  - watchOS, visionOS, tvOS — apple-architecture-core covers shared patterns;
    platform-specific skills to be added when a concrete project need arises
  - Graphics engine skills (Metal-cpp, Unity, Unreal) — deferred per BD-023
  - Codex (.codex/) port — Claude Code version must be stable first

Context: Emerged from April 2026 design analysis. The three existing template
  directories are structurally identical — only CLAUDE.md and a few agent files
  differ per platform. The real platform specialization already flows through
  documents (ARCHITECTURE.md, CLAUDE.md), not agents. Skills make this explicit
  and extensible. BD-021, BD-022, and BD-023 are deprecated into this item;
  all skill content from those items is preserved here.
Resolved: n/a

---

**BD-025 — Update DEPENDENCIES.md for Codex and Gemini CLIs**
Type: TODO(version)
Status: Open
Blockers: None — independent of BD-024; can run in parallel
Unblocks: None
File/Symbol: supporting-docs/DEPENDENCIES.md
Description: DEPENDENCIES.md currently documents only Claude Code CLI and
  project-level tools (Swift, Python, buf, etc.). Codex CLI and Gemini CLI are
  not listed. Node.js (required by Gemini CLI) is not listed. Add: Codex CLI
  installation and version requirements; Gemini CLI installation (npm global);
  Node.js as a shared dependency; any future C/C++ toolchain entries.
Context: Part of BD-024 Step 12 scope. Can be drafted independently.
Resolved: n/a

---

**BD-026 — Split scripts by language/platform**
Type: TODO(version)
Status: Open
Blockers: BD-024 Step 3 (unified template structure must be confirmed first)
Unblocks: None
File/Symbol: scripts/ directory in unified template
Description: The current monolithic format.sh and validate.sh handle all
  languages with nested conditionals. Under the unified template, language-specific
  scripts (format-swift.sh, format-python.sh, validate-swift.sh, validate-python.sh,
  validate-proto.sh, bootstrap-swift.sh, bootstrap-python.sh, test-swift.sh,
  test-python.sh) replace the monoliths. Thin wrapper scripts (format.sh,
  validate.sh, bootstrap.sh, test.sh) detect the project type and call the
  appropriate language-specific scripts. agent-post-edit-check.sh becomes
  language-aware. agent-run.sh is updated for the v9 agent roster and Gemini CLI.
  proto-gen.sh is carried forward unchanged.
Context: Part of BD-024 Step 9. See V9-DESIGN.md Decision 4 for full rationale.
Resolved: n/a

---

**BD-027 — Auditor agent design and implementation**
Type: TODO(version)
Status: Open
Blockers: BD-024 Steps 4 and 6 (skill library and Claude agent patterns must
  exist before auditor design is finalized)
Unblocks: None
File/Symbol: .claude/agents/, .codex/agents/, GEMINI.md,
  supporting-docs/METHODOLOGY.md, supporting-docs/PROMPT-TEMPLATES.md,
  .claude/skills/audit-methodology/
Description: Add a new auditor agent for full-codebase structural audits.
  Unlike reviewer (per-phase) and tester (pre-implementation strategy), the
  auditor is retrospective and periodic — run after multiple phases to find
  systemic gaps. Uses a parent + seven subagent architecture:
  auditor-architecture, auditor-code, auditor-tests, auditor-docs,
  auditor-security, auditor-ui, auditor-ops. Parent coordinates subagents
  and consolidates their reports. Requires a new audit-methodology skill.
  Also serves as the pack's reference example of subagent orchestration.
  Templates 9-12 in PROMPT-TEMPLATES.md: Template 9 rewritten as the
  auditor invocation template; Templates 10-12 superseded.
Context: Part of BD-024 Steps 10-11. See V9-DESIGN.md Decision 6 for
  full design. Updated April 2026: auditor-ui split into auditor-ui (UI
  compliance only) and auditor-ops (deployment readiness, config management,
  observability wiring) — seven subagents total.
Resolved: n/a

---

**BD-028 — PM-CHAT.md expansion for all three tools**
Type: TODO(version)
Status: Open
Blockers: BD-024 Steps 3 and 4 (structure confirmed, skill names finalized)
Unblocks: None
File/Symbol: PM-CHAT.md (template), supporting-docs/PM-CHAT.md (source),
  PLATFORM-SKILLS.md (new), GEMINI.md (new project template file),
  .claude/skills/pm-startup/SKILL.md
Description: The current PM-CHAT.md covers only Claude PM chat architecture.
  Expand to cover: Claude Web Projects, Gemini CLI, and ChatGPT Web / Codex
  — each with startup procedures, file write mechanisms, context compression,
  and cross-tool switching guidance. Create PLATFORM-SKILLS.md (skill-selection
  matrix by project type and agent). Create GEMINI.md project template context
  file. Update pm-startup skill to include PLATFORM-SKILLS.md in RAG check.
  Decide and document whether pm-startup is ported to Codex and Gemini.
Context: Part of BD-024 Step 5. See V9-DESIGN.md Part 3 for PM chat architecture.
Resolved: n/a

---

**BD-029 — Pack self-validation CI/CD**
Type: TODO(version)
Status: Open
Blockers: BD-024 Steps 3-12 (files being validated must exist first)
Unblocks: None
File/Symbol: .github/workflows/ (new)
Description: Add a GitHub Actions workflow that validates on every push to the
  pack repo: all SKILL.md files have valid frontmatter (name, description,
  allowed-tools); all .codex/agents/*.toml files parse correctly; no BACKLOG.md
  entries contain TD-TBD sentinels; README.md version table is consistent with
  the most recent git tag. Deliberate structural errors should cause clear
  workflow failures.
Context: Post-v9, after all v9 files exist. See V9-DESIGN.md Step 14.
Resolved: n/a

---

**BD-030 — TOOL-COMPARISON.md living capability reference**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: maintenance-docs/TOOL-COMPARISON.md
Description: Create a structured, date-stamped capability reference covering
  all three AI tools: PM chat capability matrix, agent invocation differences,
  skill loading mechanisms, approval model defaults, context window guidance,
  and cost routing. Supersedes GEMINI-CLI-ANALYSIS.md and ANDROID-ANALYSIS.md.
Context: Created during v9 planning phase. Committed as part of v8.10.
Resolved: April 2026, v8.10 planning docs commit.

---

**BD-032 — Validate auditor observability infrastructure vs. configuration boundary**
Type: TODO(version)
Status: Open
Blockers:
  - First v9 project with cloud-deployed observability runs a full audit (PACK-FEEDBACK.md Q1)
Unblocks: None
File/Symbol: `project-template/skills/audit-methodology/SKILL.md` — rule 21 (auditor-ops scope)
Description: The auditor splits observability into auditor-architecture (does
  the wiring exist in code?) and auditor-ops (is it configured correctly for
  the deployment target?). This boundary is logically sound but untested on
  real observability code. If the first real audit shows findings that sit at
  the boundary with no clear owner, refine rule 21 and the subagent files
  with concrete "if X, it belongs to auditor-ops; if Y, auditor-architecture"
  examples.
Context: Deferred from the v9 auditor fix pass (d2c3599). The pack repo has
  no observability code to test against. Tracked as PACK-FEEDBACK.md Q1 in
  every downstream project.
Resolved: n/a

---

**BD-033 — Validate auditor systemic error handling threshold**
Type: TODO(version)
Status: Open
Blockers:
  - First v9 project with non-trivial error handling runs a full audit (PACK-FEEDBACK.md Q2)
Unblocks: None
File/Symbol: `project-template/skills/audit-methodology/SKILL.md` — rule 16 (auditor-code scope)
Description: auditor-code audits "systemic error handling" (boundary mapping
  consistency, retry policy uniformity) as distinct from per-function
  error-handling bugs. The threshold between systemic and per-function is not
  quantified. If the first real audit shows auditor-code struggling to
  distinguish the two, add a concrete threshold to rule 16 and consider
  whether the error-handling skill needs systemic rules split from
  per-function rules.
Context: Deferred from the v9 auditor fix pass (d2c3599). The pack repo has
  no Swift/Python domain code to audit for error handling patterns. Tracked
  as PACK-FEEDBACK.md Q2.
Resolved: n/a

---

**BD-034 — Validate auditor-ui scope breadth after ops split**
Type: TODO(version)
Status: Open
Blockers:
  - First v9 project with substantial UI runs a full audit (PACK-FEEDBACK.md Q3)
Unblocks: None
File/Symbol: `project-template/skills/audit-methodology/SKILL.md` — rule 20 (auditor-ui scope)
Description: After splitting auditor-ui (UI compliance only) from auditor-ops
  (deployment readiness), auditor-ui covers 4 specific checks: view thickness,
  accessibility gaps, incomplete UI states, platform-specific UI conventions.
  A traditional UI audit might expect more (localization, dark mode, Dynamic
  Type, iPad split-view, custom gestures). If the first real UI audit shows
  the scope is too narrow, extend rule 20 with additional examples.
Context: Deferred from the v9 auditor fix pass (d2c3599). The pack repo has
  no UI layer. Tracked as PACK-FEEDBACK.md Q3.
Resolved: n/a

---

**BD-035 — Validate python-architecture skill loading for non-server Python**
Type: TODO(version)
Status: Open
Blockers:
  - First v9 non-server multi-file Python project runs a full audit (PACK-FEEDBACK.md Q4)
Unblocks: None
File/Symbol: `project-template/PLATFORM-SKILLS.md` — auditor-code skill assignment
Description: PLATFORM-SKILLS.md loads python-architecture for auditor-code
  only when a Python server is present. Performance anti-patterns (N+1
  queries, blocking I/O in async handlers) apply to any multi-file Python
  project. If the first real audit on a non-server Python project misses
  findings that python-architecture would have caught, expand the loading
  rule.
Context: Deferred from the v9 auditor fix pass (d2c3599). No non-server
  Python project exists to test against. Tracked as PACK-FEEDBACK.md Q4.
Resolved: n/a

---

**BD-036 — IDE and editor coverage gaps**
Type: TODO(version)
Status: Open
Blockers:
  - First v9 project reports IDE/editor coverage observations (PACK-FEEDBACK.md Q5)
Unblocks: None
File/Symbol: `xcode-companion-templates/`, `vscode-companion-templates/`,
  project-template context files (CLAUDE.md, AGENTS.md, GEMINI.md)
Description: The pack has deep Xcode integration (companion templates,
  post-edit hooks, scheme config, iOS doc sync) but thin VS Code coverage
  (basic companion templates only) and no coverage for JetBrains, Cursor,
  or other editors. If the first v9 project using a non-Xcode IDE reports
  missing workflow guidance, hook integration, or editor-specific config,
  create the relevant companion templates or skill content. Even Xcode-only
  projects may report gaps when new Xcode versions ship.
Context: Deferred from v9 Step 12 doc pass. The pack's Apple heritage means
  Xcode is deeply covered; other editors need real-world data to determine
  what's missing. Tracked as PACK-FEEDBACK.md Q5.
Resolved: n/a

---

**BD-037 — Platform update cycle observability**
Type: TODO(version)
Status: Open
Blockers:
  - First v9 project encounters a major platform update (PACK-FEEDBACK.md Q6)
Unblocks: None
File/Symbol: `project-template/skills/` (platform skills may need updates),
  project-template context files (availability guards, API references)
Description: When a major platform update ships (iOS 27, macOS 27, Python
  3.14, Swift 7, new CLI tool versions), pack skills and context files may
  become stale. Currently there is no mechanism to detect this proactively
  — the PM chat must notice and report. If the first platform update cycle
  on a v9 project reveals a pattern (which content goes stale first, how
  quickly, how the gap was discovered), use that data to build a proactive
  update checklist or CI check into the pack.
Context: Deferred from v9 Step 12 doc pass. Needs real-world observation of
  at least one platform update cycle. Tracked as PACK-FEEDBACK.md Q6.
Resolved: n/a

---

## Deferred

**BD-031 — Evaluate publishing pack skills to skills.sh**
Type: TODO(version)
Status: Deferred
Blockers: BD-024 (skills must be stable and complete before publication)
Unblocks: None
File/Symbol: n/a — external publication; no pack files change
Description: skills.sh (Vercel's cross-platform skill package manager,
  npx skills add) is becoming the standard install method for agent skills
  across Claude Code, Codex, and Gemini CLI. Publishing pack skills there
  would enable one-command installation for new projects. Evaluate feasibility,
  naming conventions, and versioning strategy for publishing the pack's Tier 1
  and Tier 2 skill libraries.
Context: Deferred until v9 skills are stable. See V9-DESIGN.md Decision 3.
Resolved: n/a

*(Items move here when pushed to a future version beyond v9, with the target version noted)*
