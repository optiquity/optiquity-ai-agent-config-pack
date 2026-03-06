# v8 Backlog

Items confirmed for the next pack version. All were identified during v7 usage
or during repo setup in March 2026. Source is noted for each item.

---

## BD-001 — Rename `ios-architect` → `apple-architect`

**Templates affected:** apple-app, monorepo  
**Files:** `.claude/agents/ios-architect.md`, `.codex/agents/ios-architect.toml`,
any references in `CLAUDE.md`, `AGENTS.md`, `QUICKSTART.md`  
**Reason:** The agent handles macOS as well as iOS/iPadOS. The current name
implies iOS-only scope, which causes confusion when using it for macOS-only
projects (e.g. OptiquityTrader). Rename everywhere and update all call examples.  
**Source:** v7 usage

---

## BD-002 — Add `post_edit_command` to `.codex/config.toml`

**Templates affected:** apple-app, python-server, monorepo  
**Files:** `.codex/config.toml` in each template  
**Reason:** Claude Code's `.claude/settings.json` already has a `PostToolUse`
hook that runs `agent-post-edit-check.sh` after every file edit. Codex has no
equivalent wired up — `post_edit_command` in `config.toml` is the Codex
counterpart. Without it, Codex edits do not trigger the build-check hook,
meaning Codex can silently break the build.  
**Source:** v7 usage

---

## BD-003 — Add scripts setup and usage docs

**Templates affected:** apple-app, python-server, monorepo  
**Files:** `QUICKSTART.md`, `CLAUDE.md`, `AGENTS.md`, and the per-version
setup guide (`.docx`)  
**Reason:** The scripts (`bootstrap.sh`, `format.sh`, `test.sh`, `validate.sh`,
`proto-gen.sh`, `agent-post-edit-check.sh`) exist and work, but there is no
section in any end-user document that explains: (1) what each script does,
(2) when to run it, (3) how to make them executable after cloning, and (4) the
expected output for a clean run. New projects routinely hit permission errors
or skip scripts entirely because they are undocumented from a usage standpoint.  
**Source:** v7 usage

---

## BD-004 — Resolve `format.sh` hook discrepancy in `.claude/settings.json`

**Templates affected:** apple-app, python-server, monorepo  
**Files:** `.claude/settings.json`, `CLAUDE.md`, `AGENTS.md`, `QUICKSTART.md`  
**Reason:** There is a mismatch between the documented behavior (format runs
automatically via PostToolUse hook) and the actual behavior in some project
configurations (format runs manually only). This causes agents to leave
unformatted code when the hook is not firing, and causes confusion about
whether to call `format.sh` explicitly in prompts. Decision required: pick
auto or manual, implement consistently across all templates, and update all
documentation to match the chosen behavior.  
**Source:** v7 usage

---

## BD-005 — Add `XCODE_SCHEME` warnings to validation scripts

**Templates affected:** apple-app, monorepo (python-server not affected)  
**Files:** `scripts/validate.sh`, `scripts/test.sh`,
`scripts/agent-post-edit-check.sh`  
**Reason:** When `XCODE_SCHEME` is not set and an `.xcodeproj` or
`.xcworkspace` exists in the repo, these scripts silently skip the
`xcodebuild` steps. Agents and developers have no indication that the
Xcode-specific validation was bypassed. Each script should detect this
condition and print a clearly visible warning, e.g.:
`⚠️  XCODE_SCHEME is not set — xcodebuild steps skipped.`  
**Source:** v7 usage

---

## BD-006 — Add `python-architect` agent and `python-architecture` skill

**Templates affected:** python-server, monorepo  
**Files:** `.claude/agents/python-architect.md`,
`.codex/agents/python-architect.toml`,
`.claude/skills/python-architecture/SKILL.md`,
`.codex/skills/python-architecture/SKILL.md` (+ agents/ subfolder),
`CLAUDE.md`, `AGENTS.md`, `QUICKSTART.md` routing tables  
**Reason:** The apple-app template has `ios-architect` (to be renamed
`apple-architect` per BD-001) for architecture-phase work. The python-server
and monorepo templates have no equivalent specialist. Architecture decisions
for the Python/gRPC server layer — service decomposition, grpc.aio patterns,
middleware, interceptor design — are currently handled by the generic `planner`
agent, which lacks the depth of a dedicated specialist. The new skill should
mirror the structure of `ios-architecture/SKILL.md`.  
**Source:** v7 usage

---

## BD-007 — Add new-project generation (SETUP.md + AGENT_KICKOFF.md templates)

**Templates affected:** All three (or as a pack-root utility)  
**Files:** New — either `supporting-docs/new-project-guide.md` (fill-in-the-blanks
template) or a `scripts/new-project.sh` script at the pack root  
**Reason:** The pack provides per-project templates (`CLAUDE.md`, `AGENTS.md`,
scripts) but has no guidance or tooling for the steps that come *before* those
files are useful: creating the GitHub repo, setting up the Xcode project, and
generating the initial agent kickoff prompt. These are currently done manually.
Reference implementation: the four files in `Initial_Setup.zip` (dated
March 17, 2026), which were manually produced for OptiquityTrader and contain:
- `CLAUDE.md` — customised from the apple-app template for OT
- `AGENTS.md` — customised from the apple-app template for OT
- `SETUP.md` — step-by-step GitHub + Xcode setup guide for the specific project
- `AGENT_KICKOFF.md` — the architecture phase kickoff prompt for Claude Code

The v8 deliverable should make it possible to produce equivalent files for any
new project without manual authoring. A `new-project.sh` script is preferred
over a static template so that project name, repo URL, target platform, and
broker/API references can be injected automatically.  
**Note:** The four OT files are intentionally excluded from this repo — they
belong in the `OptiquityTrader` project repo. They are documented here only as
the reference design for the v8 deliverable.  
**Source:** Initial_Setup.zip discovered during repo setup, March 2026

---

## How to use this file

- Each item has a `BD-NNN` identifier. Reference it in commit messages when
  the item is resolved (e.g. `feat: v8 — BD-001 rename ios-architect to apple-architect`).
- When an item is resolved, move it to a `## Resolved in v8` section at the
  bottom with the resolving commit noted.
- New items discovered during v8 development go here immediately with the next
  available `BD-NNN` number.
- This file ships in the repo so agents working on v8 can read it and understand
  the full scope.
