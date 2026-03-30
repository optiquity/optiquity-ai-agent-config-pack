# Backlog

All planned improvements to the AI Agent Config Pack are tracked here.
Items are grouped by status. Each has a `BD-NNN` identifier for use in commit messages.

---

## How to use this file

- Reference items in commit messages: `feat: v9 — BD-020 description`
- When an item is resolved, move it to the `## Resolved` section with the commit hash
- Items deferred to a future version move to `## Deferred` with a version note
- New items discovered during development get the next available `BD-NNN` number
- This file ships in the repo so agents can read it and understand current scope

---

## Active — v9 Scope

### BD-020 — C++ server support analysis

**Files:** `supporting-docs/CPP-SERVER-ANALYSIS.md` (new)
**Reason:** The pack currently supports Swift (Apple client) and Python (gRPC server).
C++ is a common choice for high-performance gRPC servers and systems-level services.
An analysis document should cover: what a `cpp-server-template` would require,
C++ gRPC library choices (grpc++ official library), build system options (CMake, Bazel),
relevant agents and skills needed (cpp-architect, cpp-architecture skill), toolchain
differences, and whether any existing pack files would apply unchanged.
Analysis only — no implementation until a concrete project need arises.
**Source:** v8 post-release, March 2026

---

### BD-021 — Redesign Apple platform architecture skills (three-tier)

**Files:** New files and modifications across apple-app and monorepo templates
**Reason:** The current `ios-architecture` skill applies to all Apple targets but macOS
and iOS are not a superset/subset of each other — they are siblings with significant
platform-specific differences. A single combined skill either includes irrelevant checklist
items or misses platform-specific ones. Universal apps complicate this further.

**Proposed three-tier design:**

1. **`apple-architecture-core` skill** (new) — patterns shared across all Apple platforms:
   SwiftUI-first design, protocol abstractions at layer boundaries, immutability defaults,
   actor isolation, typed IDs, LSP compliance, SPM module structure. ~60% of current
   `ios-architecture` skill content.

2. **`ios-architecture` skill** (refocus existing) — iOS/iPadOS-specific: scene lifecycle,
   UIKit interop justification, background task design, App Store/extension boundaries,
   touch-first interaction model. Remove overlap with core.

3. **`macos-architecture` skill** (new) — macOS-specific: NSDocument-based architecture,
   multiple NSWindow management, AppDelegate lifecycle and Dock behavior, menu bar ownership
   and command validation, AppKit interop patterns, Services/AppleScript/Shortcuts
   integration, sandboxed file access model, floating panels and inspector windows.

**For universal apps:** `apple-architect` agent uses all three skills — core plus both
platform skills. Agent description updated to specify the combination per project target type.

**For future platforms** (watchOS, visionOS, tvOS): same pattern — platform-specific skill
alongside core. Not in scope for this item.

**Also required:** Update `apple-architect` agent description and phase routing tables in
CLAUDE.md and AGENTS.md to reference the correct skill combination per project type.

**Source:** v8 post-release architecture review, March 2026

---

## Resolved

### Resolved in v8 — March 2026

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
| BD-012 | Commit Methodology Guide v1 to supporting-docs/origins/ | 2fc4a0c |
| BD-013 | Gemini CLI analysis document | 9a6ba5b |
| BD-014 | Android support analysis document | 9a6ba5b |
| BD-015 | Document SETUP.md/AGENT_KICKOFF.md generation workflow | 2fc4a0c |
| BD-016 | Merge OT content into apple-app CLAUDE.md/AGENTS.md | 9cd9a7f |
| BD-017 | Fix availability guard omission in iOS 26 platform features section | 08f7158 |
| BD-018 | v7→v8 migration guide | 9a6ba5b |
| BD-019 | Desktop Commander usage and PM chat scope limits (METHODOLOGY.md) | 2fc4a0c |

---

## Deferred

*(Items move here when pushed to a future version, with the target version noted)*
