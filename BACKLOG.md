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
Unblocks: None
File/Symbol: n/a — new file `maintenance-docs/CPP-SERVER-ANALYSIS.md` to be created
Description: C++ is a common choice for high-performance gRPC servers and
  systems-level services. The `cpp-language` skill already exists in the v9
  unified template (created as part of BD-024). This analysis covers the
  remaining server-specific gap: C++ gRPC library choices (grpc++ official
  library), build system options (CMake, Bazel, Makefile), what a
  `cpp-server-architecture` skill would need to cover beyond what
  `cpp-language` already provides, toolchain differences from Python/Swift,
  and whether any existing pack files apply unchanged.
Context: Analysis only — no implementation until a concrete project need arises.
  Original framing assumed a new template directory; updated April 2026 to reflect
  the unified template model from BD-024. BD-024 resolved in v9 — the
  `cpp-language` skill now exists; only the server-specific analysis remains.
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
Status: Resolved
Blockers: None
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
Resolved: April 2026, v9.0 — unified template with 16 agents, 30 skills,
  15 scripts in `project-template/`. Three old template directories removed.
  Commits f61c776 through d4dc6f3 on v9-dev, merged to main.

---

**BD-025 — Update DEPENDENCIES.md for Codex and Gemini CLIs**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: supporting-docs/DEPENDENCIES.md
Description: DEPENDENCIES.md currently documents only Claude Code CLI and
  project-level tools (Swift, Python, buf, etc.). Codex CLI and Gemini CLI are
  not listed. Node.js (required by Gemini CLI) is not listed. Add: Codex CLI
  installation and version requirements; Gemini CLI installation (npm global);
  Node.js as a shared dependency; any future C/C++ toolchain entries.
Context: Part of BD-024 Step 12 scope. Can be drafted independently.
Resolved: April 2026, v9.0 — DEPENDENCIES.md covers Claude Code CLI, Codex CLI,
  Gemini CLI, and Node.js. Commit 5035328.

---

**BD-026 — Split scripts by language/platform**
Type: TODO(version)
Status: Resolved
Blockers: None
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
Resolved: April 2026, v9.0 — language-specific scripts (format-swift.sh,
  format-python.sh, validate-swift.sh, validate-python.sh, validate-proto.sh,
  bootstrap-swift.sh, bootstrap-python.sh, test-swift.sh, test-python.sh) with
  wrapper scripts. agent-run.sh updated for v9 roster including auditor and
  Gemini CLI. Commit fd03d11.

---

**BD-027 — Auditor agent design and implementation**
Type: TODO(version)
Status: Resolved
Blockers: None
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
Resolved: April 2026, v9.0 — parent auditor + 7 subagents across Claude,
  Codex, and Gemini. audit-methodology skill created. Template 9 rewritten;
  Templates 10-12 superseded. Commits d2c3599, 5135732.

---

**BD-028 — PM-CHAT.md expansion for all three tools**
Type: TODO(version)
Status: Resolved
Blockers: None
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
Resolved: April 2026, v9.0 — PM-CHAT.md covers Claude, Codex, and Gemini.
  PLATFORM-SKILLS.md created. Template GEMINI.md created. pm-startup skill
  updated with PLATFORM-SKILLS.md check. Commit 215f413.

---

**BD-029 — Pack self-validation CI/CD**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: .github/workflows/ (new)
Description: Add a GitHub Actions workflow that validates on every push to the
  pack repo: all SKILL.md files have valid frontmatter (name, description,
  allowed-tools); all .codex/agents/*.toml files parse correctly; no BACKLOG.md
  entries contain TD-TBD sentinels; README.md version table is consistent with
  the most recent git tag. Deliberate structural errors should cause clear
  workflow failures.
Context: Post-v9, after all v9 files exist. See V9-DESIGN.md Step 14.
Resolved: April 2026, v9.0 — `.github/workflows/validate-pack.yml` with
  SKILL.md frontmatter validation, TOML parsing, TD-TBD sentinel check,
  and version table consistency. Commit 8fe8dce.

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

**BD-038 — Dynamic skill management mid-project**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: project-level CLAUDE.md/AGENTS.md/GEMINI.md (Active skills line),
  skills/pm-startup/SKILL.md, supporting-docs/METHODOLOGY.md (Procedure 1 step 6),
  project-level PM-CHAT.md, supporting-docs/PROMPT-TEMPLATES.md (Template 1)
Description: Projects need to add or remove skills mid-project as needs evolve.

  Implemented mechanism: An **Active skills** line in the Skill loading section
  of CLAUDE.md, AGENTS.md, and GEMINI.md lists the skills currently loaded for
  the project. The PM chat writes this line during project kickoff by deriving
  skills from PLATFORM-SKILLS.md for the project's type. Mid-project changes
  update this line and the project description, then commit.

  Proactive detection: At Procedure 1 step 6 (phase gate check), the PM chat
  scans the upcoming phase for technology references not covered by the active
  skills. If a matching skill exists in the pack, it flags the developer to add
  it. If no matching skill exists, it records the gap in PACK-FEEDBACK.md for
  the pack maintainer.

  pm-startup reads and reports the active skills list at session start.

Encapsulation: Additive changes to Skill loading section (trinity files),
  pm-startup (one step), Procedure 1 (one step), PM-CHAT.md (one rule),
  Template 1 (one instruction), Workflow 1 (one sub-step), migration guide
  (one note). No agent files change. No workflow structure changes. Revertable
  by removing the Active skills line and reverting the additive steps.
Context: Design discussion April 2026. Initial design proposed a separate
  `skills:` field; revised to use an Active skills line in the existing Skill
  loading section — additive on top of PLATFORM-SKILLS.md, not a replacement.
Resolved: April 2026, v9.1 — commit f8758f9.

---

**BD-039 — Prototype / speed mode**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: BD-040 (autonomous mode references prototype gate definitions)
File/Symbol: project-level CLAUDE.md (mode: field),
  supporting-docs/METHODOLOGY.md (Procedure 1 conditional logic, new Mode section),
  supporting-docs/PM-CHAT.md
Description: Projects sometimes need to prioritize speed over correctness —
  prototypes, proof-of-concept builds, throwaway experiments. The pack currently
  has one quality setting. Prototype mode selectively relaxes gates without
  changing any agent behavior or files.

  Mode declaration: `mode: prototype` in project-level CLAUDE.md. Default is
  `mode: standard` (current behavior). Toggling requires a CLAUDE.md edit and
  commit — not a session flag — so the mode is visible in git history.
  The mode is always prominently reported in pm-startup output.

  What changes in prototype mode:
  - Reviewer findings are logged to BACKLOG.md as tech debt items but are
    non-blocking (PM chat proceeds without requiring fixes first)
  - Tester agent is skipped unless explicitly requested
  - Architect is optional before coder for phases marked exploratory in the
    implementation plan
  - validate.sh runs but non-zero exit does not block proceeding (warning logged)

  What does NOT change:
  - Agent files, scripts, skills — unchanged
  - The reviewer still runs and its output is still recorded
  - BACKLOG.md tracks all accumulated tech debt automatically; these items
    become the cleanup list when mode returns to standard

Encapsulation: All logic lives in Procedure 1 conditional branches and the PM
  chat's prompt generation. Zero changes to agent files, skill files, or scripts.
  Revertable by removing the mode: field from CLAUDE.md and reverting the
  Procedure 1 additions. Tech debt items accumulated during prototype mode
  remain in BACKLOG.md permanently.
Context: See design discussion April 2026.
Resolved: n/a

---

**BD-040 — Fully autonomous execution mode**
Type: TODO(version)
Status: Open
Blockers: BD-039 (autonomous mode references prototype gate definitions;
  both modify Procedure 1 and must be sequenced to avoid conflicts)
Unblocks: None
File/Symbol: project-level CLAUDE.md (mode: autonomous, autonomous_threshold: field),
  STATUS.md (stop marker convention), supporting-docs/METHODOLOGY.md
  (new Procedure 5 — autonomous execution loop), supporting-docs/PM-CHAT.md
Description: For well-defined projects with complete implementation plans, the
  PM chat should be able to execute an entire coder → reviewer → fix cycle
  without developer interaction, stopping only at genuine blockers.

  Mode declaration: `mode: autonomous` in project-level CLAUDE.md, with optional
  `autonomous_threshold:` specifying the reviewer finding severity that triggers a
  stop (default: any Critical finding). Toggling follows the same commit-based
  mechanism as BD-039.

  Autonomous execution loop (new Procedure 5):
  1. Read current phase from STATUS.md
  2. Verify phase is fully defined in IMPLEMENTATION_PLAN.md with a mechanically
     verifiable definition of done — if not, stop and report immediately
  3. Generate coder prompt, invoke agent, collect output
  4. Generate reviewer prompt, invoke agent, collect output
  5. If reviewer passes: commit, update STATUS.md, advance to next phase, loop
  6. If findings are below threshold: generate fix prompt, invoke coder, re-run
     reviewer, loop (max 2 fix cycles per phase before stopping)
  7. If Critical finding, fix cycles exhausted, or plan is ambiguous: write
     ⚠️ AUTONOMOUS STOP to STATUS.md with reason, commit current state, halt

  Hard limits — autonomous mode cannot:
  - Modify ARCHITECTURE.md
  - Create new phases in IMPLEMENTATION_PLAN.md
  - Skip a reviewer pass
  - Proceed past a Critical reviewer finding
  - Handle external dependencies (credentials, env setup, API keys)
  - Proceed if build fails after 2 fix cycles

  Notification: The ⚠️ AUTONOMOUS STOP marker in STATUS.md is the signal.
  Developer checks STATUS.md to see where execution stopped and why.

Encapsulation: All logic in Procedure 5 and STATUS.md conventions. Zero changes
  to agent files, skills, or scripts — agents run identically. Stop marker is
  additive to STATUS.md. Revertable by removing mode: and autonomous_threshold:
  from CLAUDE.md and removing Procedure 5 from METHODOLOGY.md.

Risk note: Requires the implementation plan phase to have a complete, mechanically
  verifiable definition of done. If the plan is vague, autonomous mode refuses to
  start for that phase. This check is the primary safeguard against wrong
  implementations being committed without review.
Context: See design discussion April 2026.
Resolved: n/a

---

**BD-041 — Project initialization brief guidance**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: project-template/PM-CHAT.md, QUICKSTART.md
Description: The PM chat currently has no guidance on what to do when a project
  starts without a defined platform, skill set, or architecture. Left unguided,
  a PM chat will attempt design decisions it is not positioned to make well.

  The correct split: platform selection, feature scope, and architecture decisions
  belong in a design conversation (Claude Web side chat or equivalent), not in the
  PM chat. The PM chat is a consumer of a design brief, not its author.

  Implemented: "Before starting a new project" section added to PM-CHAT.md
  requiring a design brief before the PM chat proceeds. Prerequisite callout
  added to QUICKSTART.md Step 10 pointing to PM-CHAT.md for the full rule.

Encapsulation: Two documentation additions only. No workflow, agent, skill, or
  script changes. Fully revertable.
Context: See design discussion April 2026.
Resolved: April 2026, v9.1 — commit 5847208.

---

**BD-042 — Move pack reference docs out of project root**
Type: TODO(version)
Status: Open
Blockers: None
Unblocks: None
File/Symbol: METHODOLOGY.md, PROMPT-TEMPLATES.md, PM-CHAT.md, PLATFORM-SKILLS.md,
  PACK-FEEDBACK.md — all currently in project root
Description: The project root accumulates 15+ markdown files, mixing project
  state files the developer uses daily (BACKLOG, STATUS, CHANGELOG, ARCHITECTURE,
  IMPLEMENTATION_PLAN) with pack reference docs rarely touched after setup
  (METHODOLOGY, PROMPT-TEMPLATES, PM-CHAT, PLATFORM-SKILLS, PACK-FEEDBACK).
  Move the five pack reference docs to a subdirectory (e.g., `docs/` or
  `pack-docs/`) to reduce root clutter.

  Files that must stay in root: CLAUDE.md, AGENTS.md, GEMINI.md (tool convention),
  README.md (git convention), agent-run.sh (invoked as ./agent-run.sh).

  Blast radius is large: every cross-reference to these files in METHODOLOGY.md,
  PROMPT-TEMPLATES.md, PM-CHAT.md, QUICKSTART.md, CLAUDE.md template, AGENTS.md
  template, GEMINI.md template, pm-startup skill, CLI-PM-SETUP.md, MIGRATION
  guide, and SETUP_TEMPLATE.md must be updated. Every existing project needs the
  same migration. Scope as a major version change with its own migration step.

Context: Identified April 2026 during v9.1 work. Deferred to reduce risk —
  v9.1 is shipping BD-038 and BD-041; adding a file-move migration on top
  would increase the blast radius beyond what a minor version should carry.
Resolved: n/a

---

**BD-043 — Gemini CLI native subagent architecture and full doc audit**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: `.gemini/agents/` (new directory, 16 agent files),
  `project-template/GEMINI.md` (strip inline role definitions),
  `project-template/agent-run.sh` (Gemini invocation redesign),
  `maintenance-docs/TOOL-COMPARISON.md`, `README.md`, `CHANGELOG.md`,
  and all files referencing Gemini agent architecture
Description: The pack currently defines all 16 Gemini agent roles inline in
  GEMINI.md and uses external orchestration via agent-run.sh for invocation.
  This is incorrect. Gemini CLI supports native subagents as individual `.md`
  files with YAML frontmatter (`name`, `description`, `tools`, `mcpServers`,
  `model`, `temperature`, `max_turns`, `timeout_mins`) stored in
  `.gemini/agents/` (project-level) or `~/.gemini/agents/` (global).
  Subagents are invoked via `@agent-name` syntax or automatic delegation —
  there is no `--agent` CLI flag. GEMINI.md is strictly a project context
  file (equivalent to CLAUDE.md), not an agent definition file.

  Scope — three workstreams:

  1. **Structural migration:** Create `.gemini/agents/` with 16 agent `.md`
     files using correct YAML frontmatter. Each file needs appropriate `tools`
     lists (read-only agents get restricted tool sets, not `*`), `model`
     selection, `temperature`, and `max_turns` values tuned per role. Strip
     all role definitions from GEMINI.md, leaving only project context.
     Redesign auditor orchestration: the auditor parent must run as the main
     session (not a subagent) to delegate to auditor-* subagents, since
     subagents cannot call other subagents. Update `agent-run.sh` Gemini
     invocation to use native subagent mechanisms.

  2. **Content audit:** Review every Gemini-related file in the pack for
     correctness against the official Gemini CLI documentation
     (https://geminicli.com/docs/). Verify directory structure, file format,
     invocation patterns, approval modes, skill loading, and MCP server
     configuration are all optimal for how Gemini CLI expects and uses them.

  3. **Documentation audit:** Exhaustive audit of ALL references to Gemini
     agents, invocation, subagents, GEMINI.md role sections, agent-run.sh
     Gemini behavior, and tool comparison entries across every file in the
     pack. This includes but is not limited to: TOOL-COMPARISON.md,
     METHODOLOGY.md, PROMPT-TEMPLATES.md, PM-CHAT.md, PLATFORM-SKILLS.md,
     PACK-AGENTS.md, QUICKSTART.md, CLI-PM-SETUP.md, MIGRATION guide,
     README.md, CHANGELOG.md, CLAUDE.md (pack), AGENTS.md (pack),
     GEMINI.md (pack), and all skill SKILL.md files that reference Gemini.

  This is v9.3.

Context: Identified April 2026 via Gemini web chat feedback. The pack's Gemini
  architecture was designed during v9 planning based on incomplete understanding
  of Gemini CLI's subagent capabilities. Official docs confirm `.gemini/agents/`
  with YAML frontmatter is the correct mechanism. See
  https://geminicli.com/docs/core/subagents/ ("Creating custom subagents" section).
Resolved: April 2026, v9.3 — 16 Gemini agent files in `.gemini/agents/`,
  GEMINI.md stripped to project context, agent-run.sh transparent translation,
  validate-pack.py three-tool parity, audit-methodology and TOOL-COMPARISON
  corrected, full doc audit across 11 files.

---

**BD-044 — Project setup paths: init-project.sh, QUICKSTART router, and existing-project onboarding**
Type: TODO(version)
Status: Unblocked
Blockers: None (design approval pass completed 2026-04-21; V10-DESIGN.md approved)
Unblocks: None
File/Symbol: `QUICKSTART.md`, `scripts/init-project.sh` (new), `supporting-docs/SETUP-NEW.md` (new), `supporting-docs/SETUP-EXISTING.md` (new), `supporting-docs/SETUP_TEMPLATE.md`, `README.md`

Description: The pack has no supported path for adding it to a project already
  under development with no AI tooling. QUICKSTART.md assumes a new project
  started from scratch. This item introduces a general-purpose onboarding
  flow for both new and existing projects and restructures QUICKSTART.md as
  the single entry point for all setup scenarios.

  Target scenario: a project with no existing AI config and no existing PM docs,
  making file conflicts minimal. Full merging of existing AI config or PM docs
  is explicitly out of scope — the PM chat handles that after the pack is
  installed and working.

  **Step 1 — Planning (required before any implementation):**
  Produce a complete list of every file that needs to change and every task
  required to implement this item. Known touch points: `QUICKSTART.md`,
  `scripts/init-project.sh` (new), `supporting-docs/SETUP-NEW.md` (new),
  `supporting-docs/SETUP-EXISTING.md` (new), `supporting-docs/SETUP_TEMPLATE.md`
  (stale `cp -r` command and QUICKSTART.md step number references), `README.md`
  (layout section). Additional touch points must be identified by auditing every
  file in the pack that references QUICKSTART.md steps, the `cp -r` setup
  command, or the project creation procedure. No implementation begins until
  this list is complete and approved.

  **Step 2 — Implementation:**
  Execute all tasks from Step 1 in a logical sequence with approval gates.
  Key deliverables:

  - `scripts/init-project.sh`: single pack-level script handling both new and
    existing projects. Runs a detection pass first and reports what it found
    and what it will do — the developer confirms before any files are written.
    Detection covers: presence of source files and git history (new vs. existing);
    language/platform markers (`.swift`, `Package.swift`, `pyproject.toml`,
    `.kt`, etc.); existing AI config (`.claude/`, `.codex/`, `.gemini/`,
    `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` — stop condition: report and require
    removal before proceeding). When a detected language or platform has no pack
    skill coverage, reports the gap; the generated PM chat prompt instructs the
    PM chat to log it to `PACK-FEEDBACK.md`.
    New project path: automates the `cp -r` and skill distribution steps.
    Existing project path: selective copy (add-don't-overwrite), `.gitignore`
    merge (append and deduplicate), skip `README.md` / `pyproject.toml` /
    `Package.swift` / any existing scripts. Script output explicitly tells the
    developer that their previous file structure is replaced by the pack's
    structure and that pack file names and locations are the standard going
    forward. At the end, outputs a one-time PM chat prompt for the developer
    to paste. The prompt includes an instruction to the developer to point the
    PM chat at any existing documentation (architecture notes, README, inline
    comments, etc.) before context file generation begins, so the PM chat can
    read them for context. No persistent onboarding skill is added to projects.

  - `QUICKSTART.md` restructured as a three-path router: new project →
    `SETUP-NEW.md`; existing project → `SETUP-EXISTING.md`; pack version
    upgrade → `MIGRATION-vN-to-vM.md` for the relevant version pair. One or
    two sentences per path. No procedural content.

  - `supporting-docs/SETUP-NEW.md`: current QUICKSTART.md procedural content
    updated to reference `init-project.sh` instead of the manual `cp -r` step.

  - `supporting-docs/SETUP-EXISTING.md`: existing-project procedure referencing
    `init-project.sh`, describing the preview-and-confirm flow, and describing
    the one-time PM chat onboarding step. Must clearly state that the old
    project file structure is gone and the pack's file names and locations are
    used from this point forward.

  - Migration guide convention: version-specific migration guides are always
    named `MIGRATION-vN-to-vM.md` and always land in `supporting-docs/`. This
    convention must be documented in `SETUP-NEW.md`, `SETUP-EXISTING.md`, or
    a central reference so it is followed consistently for all future major
    version upgrades.

  - All additional doc updates identified in Step 1.

  **Step 3 — Verification:**
  Manual testing against real repos covering all three paths:
  - New project: run `init-project.sh` against an empty directory; verify
    all template files land correctly, skills distribute, bootstrap runs.
  - Existing project: run against a real project with no AI config; verify
    preview output is accurate, selective copy and `.gitignore` merge are
    correct, no existing files are overwritten, developer transition message
    is present, PM chat prompt is generated and includes the existing-docs
    pointer instruction.
  - Pack version upgrade: follow `MIGRATION-vN-to-vM.md` end-to-end; verify
    no regressions in the migration procedure from the QUICKSTART.md restructure.
  Update `validate-pack.py` if new required pack files are introduced.
  Confirm `SETUP_TEMPLATE.md` still produces a correct project `SETUP.md`
  after its content is updated.

Context: Design discussion April 2026. The pack currently has no onboarding
  path for projects already under development. `init-project.sh` usage must
  be clearly documented — when to run it (once per project, from the pack
  directory), how it differs from `bootstrap.sh` (bootstrap runs inside a
  project repeatedly on each machine checkout; init-project.sh runs once from
  the pack to create or configure a project). Moved to v10 scope — migration
  automation overlaps with the v10 migration script (BD-046). See
  maintenance-docs/V10-PREDESIGN.md Candidate Decision 10.

---

**BD-045 — Champion the capabilities design pattern alongside LSP in architecture guidance**
Type: TODO(version)
Status: Unblocked
Blockers: None (design approval pass completed 2026-04-21; V10-DESIGN.md approved;
  sequencing confirmed: BD-045 first in implementation order)
Unblocks: None
File/Symbol: `project-template/CLAUDE.md`, `project-template/AGENTS.md`, `project-template/GEMINI.md`, `project-template/skills/apple-architecture-core/SKILL.md`, `project-template/skills/python-best-practices/SKILL.md`, `project-template/skills/architecture-review/SKILL.md`, `project-template/.claude/agents/auditor-architecture.md`, `project-template/.codex/agents/auditor-architecture.toml`, `project-template/.gemini/agents/auditor-architecture.md`

Description: The pack mentions capability checks only reactively, as the approved
  escape hatch for LSP compliance ("use capability flags or feature checks for
  all implementation differences"). It never defines the capabilities pattern,
  never explains why it works, and never champions it as a design tool to reach
  for during architecture. Agents reading the pack understand that capability
  flags are acceptable — not that they are a first-class architectural pattern
  worth designing for from the start.

  **What the capabilities pattern is:**
  The capabilities pattern makes what a type supports an explicit, queryable
  first-class concern — so callers can check support before invoking behavior,
  rather than discovering unsupported operations through exceptions or silent
  failures at runtime. It takes two complementary forms:

  - **Value-based capabilities:** A type exposes a value (bitmask, flag set,
    enum set, or similar) enumerating the operations it supports. A caller
    checks the capability value before invoking the corresponding operation.
    Capability validation happens at association or initialization time —
    incompatible pairings are rejected before they can produce runtime errors.
    No exceptions are thrown for unsupported operations because callers never
    invoke them without first confirming support.

  - **Interface-based capabilities:** A type declares conformance to a small,
    focused interface (protocol, trait, interface, abstract base class, or
    equivalent in the implementation language) only when it genuinely supports
    that behavior. Callers query for the interface before invoking. Types that
    don't support a behavior simply don't expose the interface — no silent
    no-ops, no unconditional throws. The language mechanism varies
    (compile-time or runtime conformance checks, duck typing, structural
    subtyping, etc.) but the intent is the same: make the capability
    discoverable without invoking it.

  Both forms share the same intent: make supported behaviors explicit and
  queryable, eliminating the need for callers to discover limitations through
  exceptions, silent failures, or branching on concrete types.

  **How capabilities and LSP relate:**
  LSP and the capabilities pattern are both required coding practices, applied
  independently. LSP is a correctness constraint on interface design — every
  method declared in an interface must have a meaningful implementation in
  every conforming type. The capabilities pattern is an architectural tool for
  making supported behaviors explicit and queryable. Neither is a prerequisite
  for the other, and neither is the motivation for the other.

  They work well together when both are present: a codebase that applies both
  avoids a wide class of runtime surprises — callers know what an abstraction
  supports before invoking it, and every declared interface method is
  meaningfully implemented. But this is a benefit of using both, not a
  dependency between them. Each stands on its own merits and is required
  regardless of whether the other is in use.

  **What to add — all nine locations:**

  1. **Trinity files (CLAUDE.md, AGENTS.md, GEMINI.md):** Add a "Capabilities
     pattern" section near the existing Liskov Substitution Principle section.
     Define both forms (value-based and interface-based) in language-agnostic
     terms. Explicitly state that capabilities and LSP are independent required
     practices that work well together. Add "Branching on concrete types to
     discover what an abstraction supports, instead of querying a capability
     value or interface" to the anti-patterns list. Update all three files in
     the same commit per the trinity rule. The pattern is not tool- or
     language-specific.

  2. **Language-specific skills (`apple-architecture-core`,
     `python-best-practices`, and any future language skills):** Each skill
     should express the capabilities pattern in language-appropriate terms —
     what the idiomatic value-based and interface-based forms look like in
     that language, and where capability validation belongs in that language's
     typical architecture. Implementation details (language mechanisms, naming
     conventions) are language-specific; the pattern's intent is not.

  3. **`architecture-review` skill:** Extend the LSP compliance rule to also
     flag: interface implementations that throw "not supported" for operations
     that could instead be gated by a capability check; caller code that
     branches on concrete types to discover what an abstraction supports; and
     absence of any capability mechanism in types that have variable supported
     operation sets across implementations.

  4. **`auditor-architecture` agent (all three tool versions):** Extend the
     "LSP compliance" audit bullet to also cover capability pattern adherence —
     specifically: concrete type interrogation that could be replaced by
     capability checks, and "not supported" throws or silent no-ops that
     indicate a missing capability gate.

Context: Identified April 2026 via OT project, which implements capability
  masks and interface-based capability checks as the sole sanctioned mechanism
  for handling implementation differences across broker, account, and quote
  service types. The pattern prevents both LSP violations and encapsulation
  violations and is documented in OT ARCHITECTURE.md §2h. The pack's current
  guidance leads agents to discover the pattern reactively (when fixing an LSP
  violation) rather than reaching for it proactively during design. The pattern
  is language-agnostic — the implementation mechanism varies by language but
  the design intent is consistent across all typed systems.

---

**BD-046 — v10: Custom agent/skill support and prompt template reorganization**
Type: TODO(version)
Status: Unblocked
Blockers: None (design approval pass completed 2026-04-21; V10-DESIGN.md approved)
Unblocks: None
File/Symbol: maintenance-docs/V10-DESIGN.md — approved design record (supersedes V10-PREDESIGN.md)
Description: v10 addresses three problems in one major version. First:
  no structured mechanism exists for projects to add custom agents or
  skills — manual additions are invisible to the PM chat workflow and
  destroyed by pack upgrades. Second: PROMPT-TEMPLATES.md is a 765-line
  monolith with no per-agent organization and no home for custom agent
  prompts. Third: BD-044 (init-project.sh and QUICKSTART router) and
  BD-045 (capabilities pattern in architecture guidance) are folded into
  v10 because they touch the same files as the core v10 work and
  batching avoids multiple migration passes. Solution summary: x-
  prefixed custom files in existing tool directories, PM-chat-driven
  creation and registration workflow, per-agent prompt files in
  docs/pack/prompts/, automatic x- file preservation in migration
  scripts, and init-project.sh for new and existing project onboarding.
  Requires MIGRATION-v9-to-v10.md with automatable migration option.
  Migration baseline: latest v9.x only.
Context: Full design discussion captured in V10-PREDESIGN.md including
  candidate decisions, open questions, touch point inventory, and PM
  chat workflow outline. V10-PREDESIGN.md must be updated with approved
  design before any implementation begins. This item should not move
  to Unblocked until V10-PREDESIGN.md has been through a formal design
  approval pass and all Part 3 open questions are resolved.
Resolved: n/a

---

**BD-047 — PM chat kickoff auto-discovery and install-check enhancement**
Type: TODO(version)
Status: Resolved
Blockers: None (can begin after Phase 3-AC completes; planner/architect pass
  is the first implementation step, not a backlog-level blocker). **v10.0 ship-blocker.**
Unblocks: None
File/Symbol: `project-template/docs/pack/prompts/pm-chat.md` (Variant: kickoff),
  `supporting-docs/SETUP-NEW.md` (Steps 5–6), `supporting-docs/SETUP-EXISTING.md`
  (Steps 5–6)

Description: Enhance `pm-chat.md` Variant: kickoff so the PM chat auto-discovers
  Xcode scheme / simulator values (via `xcodebuild -list` and
  `xcrun simctl list devices available`), detects missing brew tools
  (swift-format, buf, swift-protobuf, grpc-swift), prompts for `brew install`
  with developer approval, edits `scripts/validate.sh`, `scripts/test.sh`,
  `.claude/settings.json`, and `scripts/format.sh` with the resolved values,
  and handles Xcode companion files (machine-level `cp` with confirmation).

  **Shell-out-capability detection:** Adapt behavior to Bash-capable CLI
  surfaces (Claude Code CLI, Codex CLI, Gemini CLI, Claude Desktop with
  filesystem MCP / Desktop Commander) vs. Claude Web without Desktop Commander
  — the latter falls back to the manual instructions documented in current
  SETUP-NEW.md / SETUP-EXISTING.md Steps 5–6.

  **Documentation updates:** SETUP-NEW.md and SETUP-EXISTING.md Steps 5–6
  change to "PM chat handles this during kickoff" with a manual-alternative
  fallback section for non-Bash surfaces.

  **Principle:** Developer is the decision-maker, not a copy/paste executor.
  Every auto-discovered value and every install/edit action is confirmed
  before the PM chat writes or runs anything.

  **Phase 3-B scope outline (in v10 implementation sequence, between
  Phase 3-AC Gate E2 and Phase 4 Gate F):**
  1. Planner/architect pass designing auto-discovery flow, confirmation
     gates, and error handling for each branch (missing Xcode, missing
     brew, ambiguous scheme list, no simulators available, non-Bash surface).
  2. Enhance `docs/pack/prompts/pm-chat.md` Variant: kickoff with the
     auto-discovery + install-check segment.
  3. Update `SETUP-NEW.md` and `SETUP-EXISTING.md` Steps 5–6.
  4. Shell-out-capability detection logic with documented fallback path.

  Estimated 2–3 commits plus the Phase 3-B design doc.

Context: Current SETUP-NEW.md and SETUP-EXISTING.md describe manual
  copy/paste steps (Step 5 Xcode scheme vars; Step 6 brew installs; Step 6
  in SETUP-NEW for Xcode companion files) in surfaces where the PM chat has
  Bash capability and could automate the work behind confirmation gates.
  Identified 2026-04-24 as the v10 implementer reached Gate E; designated
  a v10.0 ship-blocker the same day. Lands as Phase 3-B between Phase 3-AC
  (Gate E2) and Phase 4 (Gate F).
Resolved: 2026-04-24 — Phase 3-B landed on v10-dev (commits 1c5116c, db416a0, 2a0c8d5; design/plan prep in 6d6ab6a). METHODOLOGY.md Procedure 7 hosts the K1/K2/K3 auto-discovery + Forms R/I/E/M; pm-chat.md Variant: kickoff slimmed with continuation pointer; SETUP-NEW.md § Manual fallback (5.A–5.D) + SETUP-EXISTING.md Step 5 rewrite provide the non-shell path.

---

**BD-048 — Capability-addition discovery + install-check symmetry with kickoff**
Type: TODO(version)
Status: Open
Blockers: None (BD-047 was the blocker; it is now Resolved)
Unblocks: None
File/Symbol: `scripts/add-capability.sh`; `supporting-docs/METHODOLOGY.md` Procedure 6

Description: `scripts/add-capability.sh` today only performs trinity-placeholder
  file plumbing; it does not propose `brew install grpcio-tools` / `uv add ...` /
  machine-level installs when the developer adds a new pack-supported dimension
  (platform, language, protocol). Mirror the BD-047 kickoff auto-discovery +
  install-check pattern at capability-addition time. Implementation options:
  either extend Procedure 6 with a kickoff-style Form R/I/E/M sub-procedure,
  or add a new Variant: capability-added-kickoff to
  `docs/pack/prompts/pm-chat.md` that the `add-capability.sh` A7 stage invokes.
Context: Identified during BD-047 Phase 3-B planning (2026-04). Drafted in
  V10-PHASE-3B-PLAN-v2.md Part 10. Deferred out of v10.0 scope per
  V10-PHASE-3B-DESIGN.md Part 14 / V10-PHASE-3B-PLAN.md Q14-5 — keeps v10.0
  ship-blocker surface focused on kickoff. Candidate for v10.1 or later.
Resolved: n/a

---

**BD-049 — Prompt template labeled-section convention + validate-pack.py Check 10**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: project-template/docs/pack/prompts/architect.md,
  project-template/docs/pack/prompts/auditor.md,
  project-template/docs/pack/prompts/coder.md,
  project-template/docs/pack/prompts/docs-researcher.md,
  project-template/docs/pack/prompts/planner.md,
  project-template/docs/pack/prompts/pm-chat.md,
  project-template/docs/pack/prompts/reviewer.md,
  project-template/docs/pack/prompts/tester.md,
  project-template/docs/pack/prompts/PROMPT-AUTHORING.md (DELETED in v10.0),
  supporting-docs/METHODOLOGY.md § Prompt Authoring Principles,
  scripts/validate-pack.py (Check 10 added; Check 6 reformulated),
  scripts/lib/detect.sh,
  scripts/test-detect.sh,
  scripts/init-project.sh,
  scripts/migrate-v9-to-v10.sh,
  README.md,
  project-template/docs/pack/PM-CHAT.md,
  supporting-docs/MIGRATION-v9-to-v10.md

Description: Phase 4 audit of v10.0 surfaced inconsistency between the pack's
  stated Prompt Authoring Principles in METHODOLOGY.md and the actual
  content of the ten prompt templates that ship. Only coder.md Variant:
  fix-cycle surfaced the labeled triad (Problem / Expected behavior /
  Success criteria); the other variants either buried the triad in prose
  or omitted it entirely. METHODOLOGY's existing "Exceptions — where
  prescriptive content is appropriate" subsection was murky enough to be
  read as licensing solutions in the prompt.

  This item lands the labeled-section convention across all 12 in-scope
  prompt template variants, replaces METHODOLOGY's § Prompt Authoring
  Principles with the architect's draft text (mandatory triad on every
  prompt, format-vs-solution distinction, file-based-reporting rule,
  canonical section order), DELETES PROMPT-AUTHORING.md (the directory-
  guidance file collapsed to a 16-line cross-reference per the planner
  spec, which the project lead then chose to delete entirely; the
  surviving directory-guidance content moved into METHODOLOGY.md as a
  new "About docs/pack/prompts/" subsection), updates 8 deletion-
  cascade dependents (validate-pack.py Check 6, detect.sh,
  test-detect.sh, init-project.sh, migrate-v9-to-v10.sh, README.md,
  PM-CHAT.md, MIGRATION-v9-to-v10.md), and adds a new validate-pack.py
  Check 10 that enforces triad presence on every in-scope variant.

  Per the resolved Q1b: the per-fix middle label in coder.md Variant:
  fix-cycle was renamed Expected behavior: → Goal: for label
  consistency with the prompt-level triad.

  Per the resolved Q2b: pm-chat.md Variant: kickoff (a context handoff,
  not an agent-task prompt) is the one exception to the convention; an
  inline **Convention exception:** callout marks it, and the new
  Check 10 identifies the exemption via that literal substring.

  Per the resolved Q4b: the multi-part phase header convention moved
  from PROMPT-AUTHORING.md into METHODOLOGY.md § Prompt Authoring
  Principles alongside the file-based-reporting subsection.

Context: Identified during Phase 4 audit (April 2026). The audit closed
  with C-V10-01 through C-V10-14 landed (v10-dev tip 459161b or
  descendant); this work landed before C-V10-15 final verification per
  architect design pass V10-PROMPT-STRUCTURE-DESIGN.md (committed
  aff447f) and planner pass V10-PROMPT-STRUCTURE-PLAN.md (committed
  aff447f). Implementation commit follows this Pack Chat work.
Resolved: April 2026, v10.0 — commit f81678f.

---

**BD-050 — Kickoff surface-declaration gate auto-inferable + kickoff prose hardcoded environmental assumptions (F-A)**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: supporting-docs/METHODOLOGY.md § Procedure 7.0,
  supporting-docs/METHODOLOGY.md § Procedure 7.6 (Preview rendering rule),
  supporting-docs/METHODOLOGY.md § 7.2.3 / § 7.2.4 / § 7.3.1 / § 7.3.2 (cross-references),
  project-template/docs/pack/prompts/pm-chat.md Variant: kickoff lines 42–58, 84,
  project-template/docs/pack/prompts/pm-chat.md Variant: generate-agent-kickoff line 276 (path piggyback)

Description: Two related sub-defects in the kickoff variant of pm-chat.md surfaced
  during Phase 4 verification. F-A.1: assistant proceeded past the surface-declaration
  gate without explicit reply when running on shell-capable surfaces (observed in
  §4.1 F1 + §4.7 M-OT; predicted on Codex/Gemini/Desktop Commander per §4.2
  docs-research). Same auto-inference pattern collapsed Form I + Form M into Form R
  results table. F-A.2: kickoff body declared "GitHub connector is connected" +
  "search project knowledge" as facts (false on plain Web with no Project + connector
  per §4.3 evidence).

  Resolution: F-A.1 direction β (semantic acceptance with one-message no-action exit
  ramp; sanctioned-by-inference) + Form I/M preview formalization in METHODOLOGY § 7.6.
  F-A.2 direction (b) always-discover (decouple project-context doc list from
  retrieval mechanism — same principle as F-G applied to kickoff prose). Plus
  piggyback F-D path-stale fixes on pm-chat.md lines 84 + 276.

  Behavioral re-test confirmed (V10-PHASE-4-VERIFICATION.md §14): assistant
  declared `shell` AND paused for explicit `yes` reply before Form R discovery;
  assistant read 4 project docs by filesystem (no GitHub-connector assertion);
  Form I idempotency note rendered inline in Form R results table per § 7.6 Preview.
Context: Identified during Phase 4 verification (April 2026). See
  maintenance-docs/V10-F-A-DESIGN.md and maintenance-docs/V10-F-A-PLAN.md for full
  design rationale and implementation plan. Cross-surface verification on Codex/
  Gemini/Desktop Commander deferred to BD-055/BD-056/BD-057/BD-058 (v10.1).
Resolved: April 2026, v10.0 — commits cc5d7d0 (design+plan) + 385dfe2 (10-edit
  patch including 4 METHODOLOGY edits + 6 pm-chat.md edits) + 92c2428 (§13 delta
  verification) + c1039cd (§14 post-ship behavioral re-test).

---

**BD-051 — METHODOLOGY canonical location at docs/pack/ + legacy cleanup (F-C + F-D, combined)**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: scripts/init-project.sh (S6 stage + blast_radius_sweep PROMPT-TEMPLATES exclusion),
  scripts/migrate-v9-to-v10.sh (S5 stage),
  supporting-docs/MIGRATION-v9-to-v10.md (S5 row prose),
  project-template/README.md (cp example + directory-boundary prose),
  maintenance-docs/V10-PHASE-4-VERIFICATION-PLAN-v2.md (path-assertion alignment)

Description: Two related defects with one root cause and one fix. F-C: legacy
  docs/pack/METHODOLOGY.md not cleaned up by migrate-v9-to-v10.sh — projects
  with METHODOLOGY at docs/pack/ pre-migration ended up with both root and
  docs/pack/ copies. F-D: v10 design contradiction — trinity files (CLAUDE.md
  line 275, AGENTS.md line 198, GEMINI.md line 229) said canonical location is
  docs/pack/METHODOLOGY.md, but init-project.sh and migrate-v9-to-v10.sh installed
  to project root. M-OT post-migration assistant in §4.7 read the trinity, picked
  docs/pack/ as canonical, and recommended `git mv root → docs/pack/` — direct
  evidence of downstream-agent confusion from the contradiction.

  Resolution: V10-DESIGN.md prescribed docs/pack/ in three independent places
  (Part 7 §7.6 init S6, S5 migration spec, init banner); the scripts drifted
  off-spec without an overruling design decision. F-D fix restores implementation
  to V10-DESIGN.md spec: canonical METHODOLOGY.md location is docs/pack/
  METHODOLOGY.md. Migration script S5 handles all 4 pre-states (docs/pack only /
  root only / both / neither): backs up whichever is present, writes v10 content
  to docs/pack/, removes any stale root copy. F-C auto-resolved by same script
  edit. Init-project.sh warns on stale root for existing projects (does not
  delete — operator action expected); blast_radius_sweep grep extended with
  --exclude='METHODOLOGY.md' so legitimate Procedure 5-R PROMPT-TEMPLATES
  references in METHODOLOGY don't trip the post-S6 sweep.

  Delta verification (V10-PHASE-4-VERIFICATION.md §10) confirmed all 4
  pre-state cases produce correct post-state with backup contracts honored.
Context: F-D discovered during project-lead post-§4.8 inspection of OT clone
  (April 2026); F-C identified separately during §4.6 OT migration. Combined into
  single BD per architect rec (V10-F-D-DESIGN.md §6) — shared root cause and
  shared fix. See V10-F-D-DESIGN.md and V10-F-D-PLAN.md for full design and
  cascade rationale.
Resolved: April 2026, v10.0 — commits 1de2d23 (design+plan) + 603234e (5-file
  patch) + 55d1834 (blast_radius_sweep follow-on fix surfaced during §10.1
  harness) + 9ae09c8 (§10 delta verification).

---

**BD-052 — Migration leaves Pack version stale in STATUS.md (F-E)**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: supporting-docs/METHODOLOGY.md § Procedure 5-S (Task A),
  scripts/migrate-v9-to-v10.sh (S7 sentinel write),
  project-template/skills/pm-startup/SKILL.md (Step 0 trigger detection),
  supporting-docs/MIGRATION-v9-to-v10.md (Step 4 routing inventory)

Description: migrate-v9-to-v10.sh did not update project-internal "Pack version"
  markers that v9.3 user projects commonly carry (e.g., **AI Agent Config Pack**:
  v9 in docs/project/STATUS.md). Post-migration the project said it was still on
  v9 even though the pack content had been migrated to v10. The PM chat's
  /pm-startup correctly flagged this in OT (reported Pack version: v9 despite
  v10-migrated content). Real-world impact: developers reading STATUS.md
  post-migration get inconsistent signals about which pack version they're on.

  Resolution: combined with BD-053 (F-F) under one Procedure 5-S — Post-migration
  housekeeping. Triggered by sentinel `.pack-migration-backup/v9.3-to-v10.0/
  postrun-pending` written unconditionally by migrate-v9-to-v10.sh S7. Procedure
  5-S Task A scans STATUS.md priority list (docs/project/STATUS.md →
  docs/STATUS.md → STATUS.md, first-existing-wins) for case-insensitive lines
  containing both "AI Agent Config Pack" (or "Pack version") and a v9 token.
  Per match: PM chat proposes update to current pack version (read from
  docs/pack/METHODOLOGY.md first 5 lines, matching pm-startup Step 6).
  Developer approves / edits / skips per match.

  Behavioral re-test (V10-PHASE-4-VERIFICATION.md §14.4) confirmed: /pm-startup
  Step 0 detected POSTRUN-PENDING sentinel, routed to Procedure 5-S, Task A
  found 1 match (STATUS.md:113 v9 marker), proposed update, awaited authorization.
Context: Discovered during Phase 4 supplementary findings (post-§4.8 /pm-startup
  on OT clone, April 2026). See V10-F-E-F-F-DESIGN.md and V10-F-E-F-F-PLAN.md.
Resolved: April 2026, v10.0 — commits 9b8af6c (design+plan) + f266166 (4-file
  patch including Procedure 5-S body + S7 sentinel write + pm-startup Step 0 +
  MIGRATION doc routing) + 6d296f8 (§11 delta verification).

---

**BD-053 — Migration does not address unfilled trinity placeholders (F-F)**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: supporting-docs/METHODOLOGY.md § Procedure 5-S (Task B)

Description: A v9.3 user project may have left [PROJECT_NAME], [PLATFORM_TARGETS],
  [TRANSPORT], and Active-skills line placeholders unfilled in CLAUDE.md /
  AGENTS.md / GEMINI.md (this is the case in OT — placeholders never filled).
  Pre-migration migrate-v9-to-v10.sh S5 trinity splice/merge ran unconditionally
  but did not detect or surface unfilled placeholders. Post-migration projects
  could carry literal [PROJECT_NAME] text in their context files indefinitely;
  AI agents reading those files would get template-default identifiers.

  Resolution: Task B of Procedure 5-S (combined with BD-052/F-E under one
  procedure per architect rec — shared trigger, shared lifecycle, shared cleanup).
  Greps CLAUDE.md / AGENTS.md / GEMINI.md for whitelist placeholders
  ([PROJECT_NAME], [PLATFORM_TARGETS], [TRANSPORT], [PLATFORM_DEFAULTS],
  [PLATFORM_ARCHITECTURE], [LANGUAGE_RULES], [GRPC_RULES], [PLATFORM_SECURITY],
  [PLATFORM_TESTING], [PLATFORM_ANTIPATTERNS]) plus the literal Active-skills
  placeholder line. For project-identifier placeholders: standalone Q&A (NOT
  full Procedure 7 kickoff per OQ-F-F-1) — PM chat proposes values; developer
  approves; PM chat applies TRIO-byte-identical across all three trinity files.
  For section placeholders: references loaded skills' content. Active-skills
  line: simpler standalone Q&A reading docs/pack/PLATFORM-SKILLS.md.

  Behavioral re-test (V10-PHASE-4-VERIFICATION.md §14.4) confirmed: Task B
  found whitelist matches in OT trinity (TRIO-symmetric: [PROJECT_NAME] × 2,
  [PLATFORM_TARGETS] × 2, [TRANSPORT] × 1 per file); Active-skills correctly
  identified as already-populated (no Q&A needed); section placeholders
  correctly identified as already filled by skills (no matches). Standalone
  Q&A initiated for project identifiers.
Context: Discovered during Phase 4 supplementary findings (post-§4.8 /pm-startup
  on OT clone, April 2026). Same patch as BD-052.
Resolved: April 2026, v10.0 — same commits as BD-052 (combined Procedure 5-S
  patch in commit f266166).

---

**BD-054 — Solution leakage in PM-chat-generated prompts (F-G)**
Type: TODO(version)
Status: Resolved
Blockers: None
Unblocks: None
File/Symbol: supporting-docs/METHODOLOGY.md § Prompt Authoring Principles (per-agent table + Format-vs-solutions: worked examples subsection),
  project-template/docs/pack/prompts/pm-chat.md Variant: generate-agent-kickoff lines 264–287,
  project-template/skills/swift-best-practices/SKILL.md (## Design choices section, entries 39–40)

Description: Phase 4 supplementary findings (Phase 28 + Phase 32 paraphrased
  coder-prompt walk-throughs against OT clone) revealed that the v10 prompt-
  template structure (BD-049 labeled-section convention) ships a strong scaffold,
  and the PM chat applies it well, but generated prompts cross from
  format/scope/constraints into solution territory in several documented cases.
  Examples observed: parameter-injection-for-testability (Phase 28); polling
  rate, timer-suspend lifecycle, snapshot-as-value-type architectural details,
  presentation rendering choices (Phase 32). METHODOLOGY § Prompt Authoring
  Principles touched the distinction but apparently not in a way the prompt-
  generating PM chat fully internalized. Self-consistency check found one
  template (pm-chat.md Variant: generate-agent-kickoff lines 264–287) violated
  the existing METHODOLOGY rule at line 687 ("A proposed solution in an
  architect prompt is not a suggestion — it anchors the agent.").

  Resolution: new "Format-vs-solutions: worked examples" subsection in METHODOLOGY
  § Prompt Authoring Principles (between "Format requirements vs. solutions" and
  "File-based reporting"). 5 phase-anonymous Negative/Positive/Why examples
  covering testability technique, API/framework name, architectural-shape
  invention, timing/lifecycle prescription, plus 1 clarifying example that
  Files-in-scope is NOT solution leakage (recurring point of confusion).
  Per-agent table extended with `pm-chat (self-prompt)` row clarifying that
  PM chat self-prompts inherit the solution-forbidden list of every agent it
  prompts. pm-chat.md Variant: generate-agent-kickoff cleanup: delete the three
  prescriptive Notes (LSP/type-erasure, AsyncStream<Void>, ViewModel-no-SwiftUI);
  replace with single pointer checklist item naming all three trinity files +
  active skills + cross-reference to new METHODOLOGY subsection. Substantive
  lessons preserved in swift-best-practices SKILL.md "## Design choices"
  section (entries 39 + 40 — AsyncStream payload-design trade-offs and
  type-erasure-vs-protocol-elevation, framed as patterns rather than
  prescriptions). Note 3 (ViewModel-no-SwiftUI-import) already in
  apple-architecture-core SKILL.md line 11; not duplicated.
Context: Identified during Phase 4 supplementary findings (April 2026). See
  V10-F-G-DESIGN.md and V10-F-G-PLAN.md. Per-agent table pm-chat row was OQ-F-G-2
  reversal (architect recommended v10.1 defer; project lead overrode to v10.0).
  Trinity-asymmetry on the type-erasure anti-pattern (CLAUDE.md line 395 has it;
  AGENTS.md/GEMINI.md don't) implicitly resolved by substantive lesson now living
  in swift-best-practices SKILL.md.
Resolved: April 2026, v10.0 — commits f9ebff2 (design+plan) + a7d3542 (3-file
  patch) + d7ff978 (§12 delta verification).

---

## Deferred

**BD-031 — Evaluate publishing pack skills to skills.sh**
Type: TODO(version)
Status: Deferred
Blockers: Skills must be stable through at least one real project audit cycle
  before publication
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

---

**BD-055 — Codex CLI: confirm surface-declaration gate behavior under workspace-write sandbox**
Type: TODO(version)
Status: Deferred
Blockers: v10.1 — cross-surface live-run verification deferred per V10-PHASE-4-VERIFICATION-PLAN-v2 §0.6 scope decision
Unblocks: None
File/Symbol: maintenance-docs/V10-PHASE-4-VERIFICATION.md §4.2 DR1 Codex CLI
  (deviation analysis); future maintenance-docs/V10-PHASE-4-VERIFICATION-v10.1.md
  for live-run capture
Description: §4.2 docs-research pass predicted that the F-A.1 auto-inference
  pattern would recur on Codex CLI (it's a prompt-shape issue, not model-specific).
  Codex CLI runs in a workspace-write sandbox by default. Live-run verification
  needed to confirm: (1) the new F-A.1 β semantic-gate behavior fires correctly
  (assistant declares surface AND pauses for reply); (2) Form R discovery commands
  execute correctly under workspace-write sandbox without escalation prompts;
  (3) the (b) discovery instruction works on Codex's filesystem access.
Context: Deferred to v10.1 per project-lead Reading A interpretation of "no v10.1
  defects": F-B (b) cross-surface live runs are scope decisions, not defects.
  Both `codex` and `gemini` are present on the implementer's PATH but were not
  exercised live for v10.0 per §1.3 silent-scope-expansion rule.
Resolved: n/a

---

**BD-056 — Codex CLI: document Form I `yes`-path sandbox escalation in METHODOLOGY § Procedure 7.3**
Type: TODO(version)
Status: Deferred
Blockers: v10.1 — cross-surface live-run verification deferred per V10-PHASE-4-VERIFICATION-PLAN-v2 §0.6 scope decision
Unblocks: BD-055
File/Symbol: supporting-docs/METHODOLOGY.md § Procedure 7.3 (Codex-specific
  sandbox-escalation paragraph to add)
Description: §4.2 DR1 docs-research identified that Form I default is `skip`,
  but if a developer replies `yes` on Codex CLI, `brew install` (Apple-side gRPC)
  or `uv add` (Python-side gRPC) would require explicit out-of-sandbox escalation
  due to Codex's workspace-write sandbox model. METHODOLOGY § Procedure 7.3
  doesn't currently document this. Fix: add a Codex-specific sandbox-escalation
  paragraph to Procedure 7.3 explaining the prompt the developer will see and
  how to handle it. Live verification under BD-055 should confirm the prompt
  shape before the documentation lands.
Context: Identified during V10-PHASE-4-VERIFICATION.md §4.2 DR1 deviation
  analysis (April 2026). Out of v10.0 scope per §0.6.
Resolved: n/a

---

**BD-057 — Gemini CLI: add plan-mode-detection check at start of Procedure 7 Form R**
Type: TODO(version)
Status: Deferred
Blockers: v10.1 — cross-surface live-run verification deferred per V10-PHASE-4-VERIFICATION-PLAN-v2 §0.6 scope decision
Unblocks: None
File/Symbol: supporting-docs/METHODOLOGY.md § Procedure 7.1 (pre-flight check
  to add); project-template/docs/pack/prompts/pm-chat.md kickoff variant line 26
  (existing developer-facing plan-mode warning may become obsolete)
Description: §4.2 DR2 docs-research identified that Gemini CLI's `/plan` mode
  blocks shell execution (TOOL-COMPARISON.md Part 4 line 121). pm-chat.md line 26
  has a developer-facing warning ("If you are running Gemini CLI and currently in
  plan mode, exit plan mode before continuing"), but Procedure 7 itself doesn't
  detect plan-mode programmatically. If a developer replies `shell` while in plan
  mode, Form R discovery will fail with confusing errors. Fix: add a pre-flight
  check at start of Procedure 7.1 (Form R) that, if surface is Gemini, attempts
  a no-op shell command first; if it fails with the plan-mode-blocked error,
  re-prompt the developer to exit plan mode and retry. Live verification needed
  to confirm exact error shape before METHODOLOGY documentation lands.
Context: Identified during V10-PHASE-4-VERIFICATION.md §4.2 DR2 deviation
  analysis (April 2026). Architect's F-A design (V10-F-A-DESIGN.md OQ-F-A-2)
  noted: "the kickoff Before-pasting preamble's Gemini plan-mode warning becomes
  unnecessary if v10.1 lands the plan-mode-detection candidate."
Resolved: n/a

---

**BD-058 — Desktop Commander: document MCP-scope check in pre-Form-M discovery**
Type: TODO(version)
Status: Deferred
Blockers: v10.1 — cross-surface live-run verification deferred per V10-PHASE-4-VERIFICATION-PLAN-v2 §0.6 scope decision
Unblocks: None
File/Symbol: supporting-docs/METHODOLOGY.md § Procedure 7.2.4 (pre-Form-M
  MCP-scope check paragraph to add)
Description: §4.2 DR3 docs-research identified that Desktop Commander writes
  via filesystem-MCP, which has an allowlist. Writing to ~/Library/Developer/
  Xcode/CodingAssistant/ (Form M target) requires the MCP's allowlist to include
  that path — most default MCP configs scope to project root only. METHODOLOGY
  § Procedure 7.2.4 Form M default `skip` is correct (machine-level write
  requires explicit allowlist), but doesn't document the MCP-scope check or
  failure-handling. Fix: add a pre-Form-M check that, if surface is Desktop
  Commander, confirms ~/Library/Developer/Xcode/CodingAssistant/ is in the
  filesystem-MCP allowlist; if not, skip Form M and report which path needs
  adding. Live verification needed (Desktop Commander not currently present on
  implementer's machine — would need separate setup for v10.1).
Context: Identified during V10-PHASE-4-VERIFICATION.md §4.2 DR3 deviation
  analysis (April 2026). Lower priority than BD-055/BD-056/BD-057 because
  Desktop Commander is the most surface-similar to Claude Code CLI of the three
  deferred surfaces, and Form M default `skip` already protects against the
  failure mode.
Resolved: n/a

*(Items move here when pushed to a future version beyond v9, with the target version noted)*
