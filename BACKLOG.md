# Backlog

All planned improvements to the AI Agent Config Pack are tracked here.
Items are grouped by status. Each has a `BD-NNN` identifier for use in commit messages.

---

## How to use this file

- Reference items in commit messages: `feat: v8 — BD-001 rename ios-architect`
- When an item is resolved, move it to the `## Resolved` section at the bottom
  with the resolving commit hash noted
- Items deferred to a future version move to `## Deferred` with a version note
- New items discovered during development get the next available `BD-NNN` number
- This file ships in the repo so agents can read it and understand current scope

---

## Active — v8 Scope

### BD-001 — Rename `ios-architect` → `apple-architect`

**Templates affected:** apple-app, monorepo
**Files:** `.claude/agents/ios-architect.md`, `.codex/agents/ios-architect.toml`,
references in `CLAUDE.md`, `AGENTS.md`, `QUICKSTART.md`, `.codex/config.toml`
**Reason:** The agent handles macOS as well as iOS/iPadOS. The current name
implies iOS-only scope, causing confusion for macOS-only projects (e.g. OptiquityTrader).
Rename everywhere and update all call examples.
**Source:** v7 usage

---

### BD-002 — Add `post_edit_command` to `.codex/config.toml`

**Templates affected:** apple-app, python-server, monorepo
**Files:** `.codex/config.toml` in each template
**Reason:** Claude Code's `.claude/settings.json` already fires `agent-post-edit-check.sh`
after every file edit via PostToolUse hook. Codex has no equivalent — `post_edit_command`
in `config.toml` is the Codex counterpart. Without it, Codex edits silently bypass
the build check.
**Source:** v7 usage

---

### BD-003 — Add scripts setup and usage docs

**Templates affected:** apple-app, python-server, monorepo
**Files:** `QUICKSTART.md`, `CLAUDE.md`, `AGENTS.md`, per-version setup guide (.docx)
**Reason:** The scripts exist and work but no end-user document explains: (1) what each
does, (2) when to run it, (3) how to make them executable after cloning, (4) expected
output for a clean run. Projects routinely skip or misuse scripts because they are
undocumented from a usage standpoint.
**Source:** v7 usage

---

### BD-004 — Resolve `format.sh` hook discrepancy

**Templates affected:** apple-app, python-server, monorepo
**Files:** `.claude/settings.json`, `scripts/format.sh`, `CLAUDE.md`, `AGENTS.md`
**Decision:** format.sh runs manually only (not in the PostToolUse hook). Running
swift-format after every individual file edit adds latency with minimal benefit;
calling it once pre-commit is the right pattern.
**Change:** Remove misleading comment in format.sh claiming the hook calls it. Document
as manual/pre-commit in the scripts section (added via BD-003).
**Source:** v7 usage

---

### BD-005 — Add `XCODE_SCHEME` warnings to validation scripts

**Templates affected:** apple-app, monorepo
**Files:** `scripts/validate.sh`, `scripts/test.sh`, `scripts/agent-post-edit-check.sh`
**Reason:** When XCODE_SCHEME is unset and an .xcodeproj/.xcworkspace exists, these
scripts silently skip xcodebuild steps. No warning is printed.
**Change:** Each script detects this condition and prints:
`⚠️  XCODE_SCHEME is not set — xcodebuild steps skipped. Edit scripts/validate.sh.`
**Source:** v7 usage

---

### BD-006 — Add `python-architect` agent and `python-architecture` skill

**Templates affected:** python-server, monorepo
**Files:** `.claude/agents/python-architect.md`, `.codex/agents/python-architect.toml`,
`.claude/skills/python-architecture/SKILL.md`,
`.codex/skills/python-architecture/SKILL.md` (+ agents/ subfolder),
`CLAUDE.md`, `AGENTS.md`, `QUICKSTART.md` routing tables, `.codex/config.toml`
**Reason:** The apple-app template has `apple-architect` (BD-001) for architecture work.
The python-server and monorepo templates have no equivalent. Architecture decisions for
the Python/gRPC server layer are currently handled by the generic `planner` agent, which
lacks depth for: service decomposition, grpc.aio patterns, middleware, interceptor design,
repository pattern, Pydantic placement, ML inference isolation.
**Source:** v7 usage

---

### BD-007 — New-project generation templates

**Location:** `supporting-docs/` in pack repo; outputs go to project repos
**New files:**
- `supporting-docs/SETUP_TEMPLATE.md` — fill-in-the-blanks template for generating a
  project-specific SETUP.md (GitHub repo creation, Xcode setup, agent config placement,
  scripts copy, first commit, Claude project creation)
- `supporting-docs/AGENT_KICKOFF_TEMPLATE.md` — fill-in-the-blanks template for the
  architecture kickoff prompt (project description, platforms, domain types, external
  APIs, architecture constraints, output requirements)
**Reason:** SETUP.md and AGENT_KICKOFF.md are currently authored manually for each
project (reference: OptiquityTrader Initial_Setup.zip, March 2026). Both templates
include a header: "This is a starting point — customize based on your project."
**Source:** Initial_Setup.zip, March 2026

---

### BD-008 — Add `METHODOLOGY.md` to all three templates

**Location:** Project repo root (copied from template like CLAUDE.md); also uploaded
to app Claude project knowledge at setup
**Templates affected:** All three
**Contents:**
1. Tool roles (PM chat, Claude Code CLI, Xcode Coding Agent, VS Code)
2. Standard project documents (ARCHITECTURE.md, IMPLEMENTATION_PLAN.md, BACKLOG.md,
   CHANGELOG.md, STATUS.md) — what each contains, who updates it, hygiene rules
3. Agent roster and when NOT to use an agent
4. Phase structure (standard format, numbering rules)
5. Standard workflows (6 workflows: new project, per-phase standard, per-phase with
   research, fix cycle, global audit, adding a feature)
6. Audit checkpoints (milestone triggers where PM chat should recommend audits;
   references PROMPT-TEMPLATES.md for the actual prompts)
7. Doc hygiene rules
8. Warning signs
**Source:** Claude-Assisted Project Methodology Guide v1 (in this Claude project)

---

### BD-009 — Add `PROMPT-TEMPLATES.md` to pack supporting-docs

**Location:** `supporting-docs/` in pack repo; uploaded to app Claude project knowledge;
NOT copied to project repos
**Note on every template:** "This is a starting point. The PM chat should customize,
expand, or contract each prompt based on the specific project, current phase, and
context from recent reviews."
**Templates included:**
1. PM chat kickoff prompt
2. Coder prompt — standard 5-section structure
3. Reviewer prompt — standard structure with ✅/❌/⚠️ output format
4. Fix cycle prompt (generated after reviewer output)
5. Tester prompt — test strategy, read-only
6. Docs-researcher prompt
7. Planner prompt
8. BACKLOG/STATUS update prompt (standard claude, no agent)
9. Global test coverage audit prompt
10. Documentation audit prompt
11. Architecture/LSP audit prompt
12. UI audit prompt
**Source:** Claude-Assisted Project Methodology Guide v1 (in this Claude project)

---

### BD-010 — Update `QUICKSTART.md` for complete human getting-started guide

**Files:** `QUICKSTART.md`
**New sections added after existing Steps 1–10:**
- Step 11: Create the app's Claude project (connect GitHub repo, upload METHODOLOGY.md
  and PROMPT-TEMPLATES.md to project knowledge)
- Step 12: Start the PM chat (paste kickoff template from PROMPT-TEMPLATES.md)
- Step 13: Generate SETUP.md and AGENT_KICKOFF.md (two-step process: PM chat generates
  content, standard claude CLI session writes the file to the project repo)
**Source:** v7 usage + OptiquityTrader methodology

---

### BD-011 — Add VS Code companion files for python-server and monorepo templates

**Location:** New `vscode-companion-templates/` directory at pack root
**New files:**
- `vscode-companion-templates/README.md`
- `vscode-companion-templates/.vscode/settings.json` (Python/Ruff/Pyright, format-on-save)
- `vscode-companion-templates/.vscode/extensions.json` (Python, Pylance, Ruff, REST Client,
  Thunder Client, Docker, GitLens)
- `vscode-companion-templates/.vscode/tasks.json` (Run Tests, Validate, Format, proto-gen)
**Scope:** python-server-template and monorepo only. Apple-app-template: not affected.
**Source:** v8 scope decision

---

### BD-012 — Commit Methodology Guide v1 to `supporting-docs/origins/`

**File:** `supporting-docs/origins/Claude-Assisted_Project_Methodology_Guide_v1.md`
**Content:** The raw Methodology Guide v1 — OptiquityTrader-specific version with
project details intact. Historical record and source material for BD-008/BD-009.
Clearly marked at top as source material, not a deliverable.
**Source:** Claude-Assisted Project Methodology Guide v1 (in this Claude project)

---

### BD-013 — Gemini CLI analysis document

**File:** `supporting-docs/GEMINI-CLI-ANALYSIS.md`
**Content:** Analysis only (no implementation). What would need to be added or modified
to support Gemini CLI alongside Claude Code and Codex: GEMINI.md equivalent, agent/skill
analogs, settings.json equivalent, hook mechanism availability, recommended tool split,
which pack files would need to be duplicated or extended.
**Source:** v8 scope decision

---

### BD-014 — Android support analysis document

**File:** `supporting-docs/ANDROID-ANALYSIS.md`
**Content:** Analysis only (no implementation). What would need to be added for Android
app development: android-app-template, CLAUDE.md/AGENTS.md for Kotlin/Jetpack Compose/
Gradle, Android Studio companion files, android-architect agent, skill changes, gRPC
differences for Android clients. Includes Gemini CLI vs Claude Code recommendation for
Android development.
**Source:** v8 scope decision

---

### BD-015 — Document SETUP.md and AGENT_KICKOFF.md generation workflow

**Files:** `supporting-docs/METHODOLOGY.md` (Workflow 1 expanded),
`supporting-docs/PROMPT-TEMPLATES.md` (two new generation prompt templates),
`QUICKSTART.md` (Step 13 expanded)
**Reason:** The two-step generation process (PM chat generates content → standard claude
CLI writes file) needs to be documented in METHODOLOGY.md as part of Workflow 1, and
the generation prompts need to be in PROMPT-TEMPLATES.md. This is distinct from BD-007
(which creates the templates themselves) and BD-010 (which updates QUICKSTART.md).
**Source:** v8 design session

---

### BD-016 — Merge OT content improvements into apple-app-template CLAUDE.md and AGENTS.md

**Templates affected:** apple-app, monorepo (and partially python-server)
**Files:** `CLAUDE.md` (apple + monorepo), `AGENTS.md` (apple + monorepo),
`.gitignore` (all three), `.claude/settings.local.example.json` (all three)
**Changes from OptiquityTrader CLAUDE.md/AGENTS.md analysis:**
1. Add `## Liskov Substitution Principle` section (generalized from OT version)
2. Add typed ID wrapper rule to Swift coding rules
3. Add "document architecture pattern in ARCHITECTURE.md before implementation"
   to Architecture section
4. Add "Request minimum required entitlements" to Security section
5. Add anti-patterns: `Mutable global state not documented as such`,
   `Domain types in transport-layer signatures` (OT has more precise wording)
6. Merge .gitignore: add complete Xcode patterns from OT (*.dSYM, *.hmap, *.ipa,
   fastlane/ patterns, Carthage/Build/) to v7 template which already has agent-specific
   entries (.claude/settings.local.json, .mcp.json, generated/ dirs)
7. Improve `.claude/settings.local.example.json` to include common allow patterns
   (Bash(grep *), Bash(ls *), WebSearch) with a comment block explaining usage
**Source:** OptiquityTrader CLAUDE.md/AGENTS.md, March 2026

---

### BD-017 — Fix availability guard omission in iOS 26 platform features section

**Priority: HIGH — active bug in current template**
**Templates affected:** apple-app, monorepo, and both Xcode companion files
**Files:** `CLAUDE.md` (apple + monorepo), `AGENTS.md` (apple + monorepo),
`xcode-companion-templates/ClaudeAgentConfig/CLAUDE.md`,
`xcode-companion-templates/Codex/AGENTS.md`
**Problem:** The v7 template iOS 26 section says "Use `.glassEffect()` and related
modifiers" unconditionally. Any project targeting macOS 15+ or iOS 17+ that follows
this will get a compilation error — Liquid Glass and FoundationModels require macOS 26+
/ iOS 26+.
**Fix:** Add to the iOS 26 section: "If the project's deployment target is below
macOS 26 / iOS 26, all Liquid Glass and FoundationModels usage must be wrapped in
`#available(macOS 26, *)` / `#available(iOS 26, *)` guards."
**Reference:** OptiquityTrader CLAUDE.md "Xcode 26.3 platform features" section
correctly implements this pattern.
**Source:** OptiquityTrader CLAUDE.md analysis, March 2026

---

### BD-018 — v7→v8 migration guide

**File:** `supporting-docs/MIGRATION-v7-to-v8.md`
**Contents:**
- Files safe to replace entirely (Xcode companion files, .codex/config.toml, scripts)
- Files requiring manual merge (CLAUDE.md, AGENTS.md — project customizations must
  be preserved)
- New files to add to projects (METHODOLOGY.md → project repo, METHODOLOGY.md +
  PROMPT-TEMPLATES.md → Claude project knowledge)
- Agent rename impact (ios-architect → apple-architect): .md file rename, .toml rename,
  CLAUDE.md/AGENTS.md phase routing tables, any saved prompts or scripts
- .gitignore merge instructions
- OptiquityTrader-specific section: exact steps for upgrading OT from v7 to v8
**Source:** v8 design session

---

## Resolved

*(Items move here when resolved, with the resolving commit hash)*

---

## Deferred

*(Items move here when pushed to a future version, with the target version noted)*
