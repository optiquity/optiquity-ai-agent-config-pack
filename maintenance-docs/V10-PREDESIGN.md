# V10-PREDESIGN.md — AI Agent Config Pack v10 Pre-Design Document

*Created: April 2026*
*Status: DISCUSSION CAPTURE — NOT AN APPROVED DESIGN*

> ⚠️ **This document is not an approved design. Do not implement
> anything based on this document alone.**
>
> This is a structured capture of design conversations. Everything in
> Part 2 labeled "Candidate Decision" reflects what was discussed, not
> what has been decided. Everything in Part 3 is explicitly unresolved.
>
> Before any implementation begins, a formal design approval pass is
> required that:
> 1. Reviews every candidate decision and explicitly confirms or changes it
> 2. Resolves every open question in Part 3
> 3. Updates this document to reflect the approved design
> 4. Produces an explicit written record of approval
>
> The pack chat must not begin any implementation step based on this
> document in its current state. This document is the input to the
> design approval pass, not the output of it.

---

## How to use this document

**Part 1** — Why v10 exists: the three problems.
**Part 2** — Candidate decisions from the design discussion. Starting
  points for the approval pass, not settled decisions.
**Part 3** — Open questions that must be resolved before implementation.
**Part 4** — Touch point inventory. Treat as a starting checklist —
  the approval pass may add or remove items.
**Part 5** — PM chat workflow sketch. Rough outline only.
**Part 6** — Implementation constraints and backlog map.
**Part 7** — Design requirements and success criteria. Process phases
  and design constraints that V10-DESIGN.md must satisfy.
**Part 8** — V9 lessons learned. Patterns to avoid repeating.
**Part 9** — Token budget analysis requirement.
**Part 10** — Migration testing matrix dimensions.
**Part 11** — Pack development agents and skills consideration.

---

## Part 1 — Why v10 Exists

Three problems are addressed together because their solutions overlap
significantly on the same files. Separating them would require multiple
migration passes on the same projects.

### Problem 1 — No structured mechanism for custom agents and skills

Projects that need a specialized agent or skill not in the pack have
no supported path. V9-DESIGN.md Decision 7 acknowledges project-level
customization is permitted but provides only a 6-step manual checklist
with a warning label. A developer who adds a custom agent directly to
`.claude/agents/` without PM chat involvement creates a file the PM
chat cannot route to and cannot include in generated prompts. The
result is silent failure: the agent exists on disk but is invisible
to the workflow.

Pack upgrades compound this: the current migration approach uses
`rm -rf .claude/agents/ && cp -r` which destroys any custom files.
No preservation mechanism exists.

### Problem 2 — Prompt templates are monolithic and unassociated

`docs/pack/PROMPT-TEMPLATES.md` is approximately 765 lines covering
14 templates. PM-chat-internal instructions and agent-specific prompts
are mixed in a single file. The PM chat reads the entire document
whenever it needs any single template. Agents with multiple prompt
variants (coder has three) have all variants in the same
undifferentiated document. Custom agents from Problem 1 have no
natural home for their prompt templates.

### Problem 3 — Project onboarding and setup have structural gaps (BD-044, BD-045)

**BD-044:** QUICKSTART.md assumes a new project started from scratch.
A developer adding the pack to an existing project with no AI tooling
has no supported path. The current setup requires a manual `cp -r`,
manual skill distribution, no detection of existing project state,
and no PM chat prompt generated at the end of setup.

**BD-045:** The capabilities design pattern is mentioned in the pack
only as an approved escape hatch for LSP compliance. It is never
defined, never explained, and never presented as a design tool to
reach for proactively during architecture. Architecture guidance and
skills need to champion it alongside LSP as a first-class pattern.

These three problems are addressed in one major version because BD-044
touches the same migration infrastructure as Problems 1 and 2, and
BD-045 touches the same context files and skills that custom agent
support requires updating. Batching avoids multiple migration passes
on the same files.

---

## Part 2 — Candidate Decisions

> ⚠️ These are candidate decisions from design discussion. They have
> NOT been approved. Each must be reviewed and explicitly confirmed
> or changed during the design approval pass.

### Candidate Decision 1 — x- prefix for all custom files

Custom agents and skills are distinguished from pack files by an
`x-` prefix on all file and directory names. Custom files must
coexist in the same directories as pack files because each CLI tool
only scans its designated directory — there is no alternative
location. The prefix is the differentiation and preservation
mechanism.

Examples:
- Custom Claude agent: `.claude/agents/x-<name>.md`
- Custom Codex agent: `.codex/agents/x-<name>.toml`
- Custom Gemini agent: `.gemini/agents/x-<name>.md`
- Custom skill: `x-<name>/SKILL.md` in each tool's skills directory
- Custom prompt template: `docs/pack/prompts/x-<name>.md`

### Candidate Decision 2 — Custom files follow identical structure to pack files

Custom agents use identical file formats to pack agents. Custom
skills use identical structure (directory + SKILL.md). Custom prompt
files follow the same structure as pack prompt files. The PM chat
treats custom files the same as pack files — the only visible
difference is the prefix.

### Candidate Decision 3 — PM chat is the only creation mechanism

Developers never add custom agents or skills manually. The PM chat
handles all creation, documentation, and registration. If a developer
adds a file manually, the PM chat detects it at startup and phase
gate check, and prompts them to handle it through the PM chat.
The PM chat explains that manual additions without registration are
invisible to generated prompts and routing tables, and offers to
perform the registration.

### Candidate Decision 4 — PM chat can create agents from any starting point

Three creation paths:
- Developer describes the agent → PM chat creates all three tool
  formats and the prompt template
- Developer writes one tool's format → PM chat translates to the
  other two and creates the prompt template
- Developer provides an existing file → PM chat reviews, rewrites
  to pack conventions if needed, creates the other two formats

Custom skills are reviewed by the PM chat for convention compliance
before being committed.

### Candidate Decision 5 — Migration script preserves x- prefixed files

Pack upgrade scripts detect `x-` prefixed files before any
destructive operation, preserve them, run the upgrade, and restore
them. This is automatic — developers do not handle custom files
manually during upgrades.

### Candidate Decision 6 — Custom skills load the same way as pack skills

Custom skills appear in a `## Custom skills` section in
PLATFORM-SKILLS.md and are loaded by agent prompts using the same
mechanism as pack skills. No separate loading mechanism.

### Candidate Decision 7 — PLATFORM-SKILLS.md gets a Custom skills section

A `## Custom skills` section is added to PLATFORM-SKILLS.md. This
is the PM chat's reference for which custom skills exist and which
agents should load them. No new files introduced for this purpose.
PLATFORM-SKILLS.md is already read at PM chat startup.

### Candidate Decision 8 — Prompt templates reorganized into per-agent files

`docs/pack/PROMPT-TEMPLATES.md` is replaced by a directory:

```
docs/pack/prompts/
    coder.md              — standard prompt, fix cycle, mid-phase architect
    reviewer.md
    tester.md
    planner.md
    docs-researcher.md
    grpc-schema.md
    architect.md
    repo-ops.md
    auditor.md
    pm-chat.md            — Templates 1, 8, 13, 14 (PM chat internal)
    x-<n>.md              — custom agent prompts, same prefix convention
```

All variants for one agent live in one file under clearly labeled
headings. The PM chat reads only the relevant file when generating
a prompt, not the entire collection.

### Candidate Decision 9 — Custom agent prompts live in the same prompts directory

Custom agent prompt files: `docs/pack/prompts/x-<n>.md`. Same
structure as pack prompt files. No separate location for custom
prompts.

### Candidate Decision 10 — BD-044 is v10 scope

BD-044 (init-project.sh, QUICKSTART router, existing-project
onboarding) is v10 scope because its migration automation overlaps
with the v10 migration script and must be built together rather than
as a separate v9.x item.

BD-044 deliverables (from existing BACKLOG entry):
- `scripts/init-project.sh` — detection pass, preview-and-confirm,
  new project path (automates cp -r and skill distribution), existing
  project path (selective copy, .gitignore merge, PM chat prompt
  generated at end)
- `QUICKSTART.md` restructured as a three-path router: new project →
  SETUP-NEW.md; existing project → SETUP-EXISTING.md; upgrade →
  MIGRATION-vN-to-vM.md
- `supporting-docs/SETUP-NEW.md` — new project procedural content
- `supporting-docs/SETUP-EXISTING.md` — existing project procedure,
  preview-and-confirm flow, PM chat onboarding step
- Migration guide naming convention documented

### Candidate Decision 11 — BD-045 is v10 scope

BD-045 (capabilities design pattern alongside LSP) is v10 scope
because its changes touch the same context files, architecture
skills, and auditor agent files that v10 already requires updating
for custom agent support. Batching avoids a separate minor version
commit touching the same files.

BD-045 deliverables (from existing BACKLOG entry):
- Define the capabilities pattern in architecture skills
- Champion it as a proactive design tool alongside LSP
- Update auditor-architecture to check for it
- Update context files (CLAUDE.md, AGENTS.md, GEMINI.md) and
  relevant skills

### Candidate Decision 12 — v10.0 is the target version

The combined scope warrants a major version. A
`MIGRATION-v9-to-v10.md` guide is required with an automatable
migration option using the same paste-ready prompt pattern as
MIGRATION-v8-to-v9.md.

### Candidate Decision 13 — Latest v9.x is the only migration baseline

All existing projects are on the latest v9.x release. The migration
guide handles only that upgrade path. No earlier versions.

---

## Part 3 — Open Questions

> All of these are unresolved. They must be answered during the
> design approval pass before implementation begins.

### OQ-1 — Custom agent detection mechanism

Discussed: PM chat scans `.claude/agents/`, `.codex/agents/`, and
`.gemini/agents/` at startup, compares file names against the known
pack roster, treats any `x-` prefixed or unrecognized file as
custom. Flags any custom file not registered in PLATFORM-SKILLS.md
or routing tables as improperly added.

Unresolved: What is the authoritative pack roster the PM chat checks
against? Is the routing table in CLAUDE.md sufficient or does the
pack need an explicit registry? What if the roster drifts from the
actual agent files over time?

Additional (pack chat review, April 2026): `validate-pack.py` has
the agent count and name-correspondence check, but it runs in the
pack repo CI — a PM chat inside a project has no access to it. The
PM chat needs a self-contained way to know the canonical pack agent
list. Options: hardcoded in PM-CHAT.md, derived from PLATFORM-SKILLS.md
agent rows, or a new lightweight registry file. Each has different
drift and maintenance characteristics.

### OQ-2 — Codex config.toml registration

Codex requires agents to be registered in `.codex/config.toml` in
addition to existing as `.toml` files. No equivalent requirement
exists in Claude or Gemini.

Unresolved: How does the PM chat detect and repair the inconsistency
when a custom agent's `.toml` file exists but the config.toml entry
is missing, or vice versa?

### OQ-3 — Prompt template migration for existing projects

The migration replaces `docs/pack/PROMPT-TEMPLATES.md` with a
`docs/pack/prompts/` directory and multiple files. The migration
script must handle this transformation automatically.

Unresolved: PROMPT-TEMPLATES.md may have been customized for some
projects. How should migration handle custom content that does not
belong in any specific agent's file?

Additional (pack chat review, April 2026): Concrete example — the
v9.x PROMPT-TEMPLATES.md Template 8 was recently updated to include
a STATUS.md phase-title linking rule. Any migration that replaces
the monolith must carry forward all such incremental additions,
not just the original v9.0 content. Options: migration reads the
project's existing PROMPT-TEMPLATES.md and diffs against the pack's
v9.x baseline to detect customizations; or migration preserves the
old file as a backup and the PM chat reconciles after upgrade.

### OQ-4 — PM chat startup behavior after prompt reorganization

pm-startup currently reads PROMPT-TEMPLATES.md. After reorganization
it no longer exists.

Unresolved: Should pm-startup read a manifest listing available
prompt files, or is noting the directory's existence sufficient,
reading individual files only on demand?

### OQ-5 — init-project.sh and migration script relationship

BD-044's init-project.sh and the v10 migration script may share
detection logic (language markers, existing AI config detection).

Unresolved: One script with mode flags, or two separate scripts?
Where does each live in the repo?

Additional (pack chat review, April 2026): The detection logic is
shared but the write operations are completely different — fresh
copy with selective overwrite vs. in-place upgrade with x- file
preservation. Two scripts that share a common detection library
(sourced shell functions) may be cleaner than one script with mode
flags that tries to do both.

### OQ-6 — Design approval process itself

**Resolved — 2026-04-21 (Step 1, G1 gate).**

The design approval process is defined by
`maintenance-docs/V10-DESIGN-PROCESS-PLAN.md`. The process defines
actors, session formats, 13 ordered steps, 10 checkpoint gates with
developer approval at each, and the approval artifact
(V10-DESIGN.md with APPROVED status header). V10-PREDESIGN.md
receives a supersession banner when V10-DESIGN.md is approved.

### OQ-7 — Manual creation escape hatch (CD-3)

*Added by pack chat review, April 2026.*

CD-3 requires the PM chat as the only creation mechanism for custom
agents and skills. What if the developer is in a Codex-only workflow,
is offline, or simply knows what they are doing and wants to create
the files manually? Should there be a documented manual escape hatch
with the understanding that manual additions are unsupported and the
PM chat will flag them for proper registration at next startup? Or
does the "PM chat detects and offers to register" behavior (already
in CD-3) serve as the de facto escape hatch?

### OQ-8 — x- prefix collision with future pack agents (CD-5)

*Added by pack chat review, April 2026.*

CD-5 says migration scripts detect and preserve x- prefixed files.
The preservation mechanism is unspecified (temp move and restore?
in-place skip?). More importantly: what happens if a future pack
version introduces a new agent whose name collides with an existing
x- prefixed custom file? Example: a project creates `x-deployer.md`
and a future pack version adds a standard `deployer.md` agent — no
collision. But what if the project creates `x-auditor-perf.md` and
the pack later adds `auditor-perf.md`? The x- prefix avoids direct
file name collision but the conceptual overlap may cause confusion in
routing tables and prompt generation.

### OQ-9 — prompts/ directory naming and non-prompt content (CD-8)

*Added by pack chat review, April 2026.*

CD-8 proposes `docs/pack/prompts/` as the new directory. The proposed
contents include `pm-chat.md` containing Templates 1, 8, 13, 14 —
these are PM chat operational templates (kickoff, backlog/status
updates, phase gate procedures), not agent prompts. The directory
name `prompts/` implies agent prompt templates, but it would also
contain PM chat workflow templates that serve a different purpose. Is
`prompts/` the right name? Alternatives: `templates/`, `prompts-and-
procedures/`, or keep PM chat templates in a separate location.

### OQ-10 — BD item sequencing

*Added by pack chat review, April 2026.*

Part 6 notes that BD-044, BD-045, and BD-046 should not run in
parallel but does not propose an order. Observation:

- **BD-045** (capabilities pattern) is the most independent. It adds
  content to existing files without restructuring them. Lowest risk,
  no dependencies on the other two.
- **BD-046** (custom agents/skills, prompt reorg) is the most
  structural — creates new directories, moves files, changes PM chat
  behavior. This defines the v10 file structure.
- **BD-044** (init-project.sh, QUICKSTART router) depends on the
  final v10 file structure. It cannot be implemented until BD-046
  is settled because init-project.sh needs to know what it copies.

Natural order: BD-045 first, BD-046 second, BD-044 last.

**Resolved — 2026-04-21 (Step 1, G1 gate).** Order confirmed:
BD-045 → BD-046 → BD-044.

### OQ-11 — Per-agent prompt file format

*Added by pack chat review, April 2026.*

CD-8 says "all variants for one agent live in one file under clearly
labeled headings." The actual file format is unspecified. Questions:

- What is the heading structure? (`## Standard`, `## Fix Cycle`,
  `## Mid-Phase Architect Trigger` for coder?)
- Does each file have frontmatter (name, description, agent,
  variants list)?
- How does the PM chat locate the correct variant within a file —
  by heading name, by section index, or by a structured marker?
- Is the format machine-parseable or free-form markdown?

The format must be specified in the design doc before the migration
script or the PM chat workflow can be implemented.

### OQ-12 — init-project.sh detection heuristics

*Added by pack chat review, April 2026.*

BD-044 describes detection of "source files and git history" to
distinguish new from existing projects. The heuristics are
unspecified. Questions:

- What exactly constitutes "source files present"? One `.swift` file?
  A `src/` directory? A non-trivial git log?
- A repo with only a README and .gitignore — is that new or existing?
- How deep does the language scan go (top-level markers only, or
  recursive search)?
- What about monorepos with multiple language roots?

The design doc must specify the detection logic precisely enough that
the script can be implemented without judgment calls.

### OQ-13 — Capabilities pattern content (BD-045)

*Added by pack chat review, April 2026.*

BD-045 describes what to add and where (nine locations), but the
actual text for each location has not been drafted. The design doc
needs to either include the draft text or specify it precisely enough
that an implementer can write it without design-level decisions. The
trinity file section, the apple-architecture-core rules, the
python-best-practices rules, the architecture-review rule extension,
and the auditor-architecture bullet extension all need concrete
wording that is language-agnostic where required and language-specific
where appropriate.

### OQ-14 — Verification plan

*Added by pack chat review, April 2026.*

V9-DESIGN.md included a post-launch verification checklist that
drove the V9-AUDIT-REPORT.md. V10 needs the same: a structured
verification plan specifying what tests prove each deliverable is
correct. This includes:

- CI validation (validate-pack.py updates for new file structure)
- Manual testing of init-project.sh (new project, existing project)
- Manual testing of migration (v9.x to v10)
- PM chat workflow testing (custom agent creation, custom skill
  creation, detection of improperly added files)
- Prompt template migration correctness (all content preserved,
  no template lost or corrupted)
- x- file preservation through a simulated upgrade
- BD-045 content review (capabilities pattern text accurate and
  language-agnostic)

The verification plan should be part of the design doc, not deferred
to implementation.

---

## Part 4 — Touch Point Inventory

This is a starting checklist. The design approval pass will
confirm, add, or remove items.

### Pack repo

| File | Expected change |
|---|---|
| `maintenance-docs/V10-PREDESIGN.md` | This file |
| `supporting-docs/METHODOLOGY.md` | New Procedure 5: PM chat custom agent/skill workflow and detection rules |
| `project-template/docs/pack/PLATFORM-SKILLS.md` | Add `## Custom skills` section |
| `project-template/docs/pack/prompts/` | New directory; all per-agent prompt files |
| `project-template/docs/pack/PROMPT-TEMPLATES.md` | Removed — replaced by prompts/ directory |
| `QUICKSTART.md` | Three-path router (BD-044); x- preservation note |
| `scripts/init-project.sh` | New (BD-044) |
| `supporting-docs/SETUP-NEW.md` | New (BD-044) |
| `supporting-docs/SETUP-EXISTING.md` | New (BD-044) |
| `supporting-docs/MIGRATION-v9-to-v10.md` | New migration guide with automatable option |
| Migration scripts | x- file detection and preservation logic |
| CI validation script | Skip x- prefixed files in pack structure validation |
| `project-template/.codex/config.toml` | Custom agent registration documentation |
| Architecture skills | Capabilities pattern content (BD-045) |
| `project-template/CLAUDE.md`, `AGENTS.md`, `GEMINI.md` | Capabilities pattern, routing table updates |
| Auditor-architecture agent files | Capabilities pattern check (BD-045) |
| `README.md` | v10 version table |
| `CHANGELOG.md` | v10 entry |
| `BACKLOG.md` | BD-046; BD-044 and BD-045 version updated to v10 |

### In a project after installation (PM chat creates all of these)

| File | Change |
|---|---|
| `docs/pack/PLATFORM-SKILLS.md` | PM chat adds entry to `## Custom skills` section |
| `docs/pack/prompts/x-<n>.md` | PM chat creates custom agent prompt template |
| `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` | PM chat adds custom agent to routing tables |
| `.claude/agents/x-<n>.md` | PM chat creates |
| `.codex/agents/x-<n>.toml` | PM chat creates |
| `.gemini/agents/x-<n>.md` | PM chat creates |
| `.claude/skills/x-<n>/SKILL.md` | PM chat creates (if custom skill) |
| `.codex/skills/x-<n>/SKILL.md` | PM chat creates (if custom skill) |
| `.gemini/skills/x-<n>/SKILL.md` | PM chat creates (if custom skill) |
| `.codex/config.toml` | PM chat adds `[agents.x_name]` entry |
| `docs/project/BACKLOG.md` | PM chat notes custom agent/skill as project-local |

---

## Part 5 — PM Chat Workflow Sketch

*Rough outline only. The final Procedure 5 in METHODOLOGY.md will be
written during the design approval and implementation phases.*

**Adding a custom agent:**
1. Developer describes the agent to the PM chat (purpose, tools
   needed, read-only or write, prompt variants needed)
2. PM chat asks clarifying questions
3. PM chat drafts all three agent files and the prompt template,
   presents all for review
4. Developer approves or requests changes
5. PM chat proposes updates to CLAUDE.md, AGENTS.md, GEMINI.md
   routing tables, PLATFORM-SKILLS.md custom section, and
   .codex/config.toml entry
6. Developer approves; PM chat commits all in one coordinated commit

**Adding a custom skill:**
1. Developer describes the skill
2. PM chat drafts SKILL.md for all three tool directories
3. PM chat proposes PLATFORM-SKILLS.md custom section entry
   specifying which agents load the skill
4. Developer approves; PM chat commits

**Detection of improperly added files (at pm-startup and phase gate):**
The PM chat scans agent directories for files not in the pack roster
and not `x-` prefixed. If found, it surfaces the issue and offers
to handle proper registration. If a developer reports an agent is
not working, the PM chat explains that manual additions without
registration are invisible to the workflow and offers to fix it.

---

## Part 6 — Implementation Constraints and Backlog Map

**Scope confirmed — 2026-04-21 (Step 1, G1 gate):**
- CD-10 confirmed: BD-044 is v10 scope
- CD-11 confirmed: BD-045 is v10 scope
- CD-12 confirmed: v10.0 is the target version
- CD-13 confirmed: latest v9.3 is the only migration baseline (no v9.4; all projects already on v9.3)
- OQ-6 resolved: design approval process defined by V10-DESIGN-PROCESS-PLAN.md
- OQ-10 resolved: implementation order is BD-045 → BD-046 → BD-044

**Migration baseline:** v9.3 only. One path.

**Target version:** v10.0.

**Design approval required before any work begins.** This document
must be updated to reflect approved decisions before the pack chat
starts any implementation step. The status header must change from
"DISCUSSION CAPTURE — NOT AN APPROVED DESIGN" to reflect approval.

**Backlog items in v10 scope:**

| BD | Title | Notes |
|---|---|---|
| BD-044 | Project setup paths: init-project.sh, QUICKSTART router, existing-project onboarding | Moved from v9 to v10 |
| BD-045 | Champion capabilities design pattern alongside LSP | Moved to v10 — touches same files |
| BD-046 | Custom agent/skill support and prompt template reorganization | New — core v10 work |

**Sequencing note:** BD-044, BD-045, and BD-046 touch overlapping
files. Sequencing must be decided during the design approval pass.
They should not run in parallel on the same files.

---

## Part 7 — Design Requirements and Success Criteria

*Added by pack chat review, April 2026. These requirements govern
the V10-DESIGN.md document and the process that produces it.*

### Process requirements

The path from predesign to shipped v10 has four phases. No phase
begins until the previous phase is complete and approved.

1. **Process planning** — plan how to construct V10-DESIGN.md: what
   topics, what order, what inputs are needed, how to ensure nothing
   is missed.
2. **Design pass** — construct V10-DESIGN.md. No implementation.
   The design must be both elegant and complete, covering all three
   BD items with seamless integration between them.
   The design must consider the Design Requirements below but challenge them and push back when a better alternative is available and can be defended clearly. 
3. **Implementation planning** — plan every implementation step from
   the approved design, ensuring every backlog entry and detail is
   accounted for.
4. **Implementation, audit, and manual testing** — execute with
   approval gates, developer manual testing of as much as possible,
   final approval.

### Design requirements

The V10-DESIGN.md must address all of the following:

- **Automated and manual workflows.** Cover PM chat workflows, Pack
  chat workflows, script-driven automation, and developer manual
  steps. Every actor (PM chat, Pack chat, init-project.sh, migration
  script, developer) must have a clear role with no ambiguity about
  who does what.

- **Resource considerations.** Time cost and token usage. Documents
  that are read frequently must be sized for the tools that read them.
  Avoid designs that force large reads when small reads would suffice.

- **Maintenance considerations.** Single sources of truth where
  possible, while adhering to Claude Code, Codex CLI, and Gemini CLI
  rules (each tool has its own directory and file format requirements).
  Clean separation of project customizations from standard pack
  offerings so that pack upgrades do not require manual merging of
  customized content.

- **Document access patterns.** Separate documents by when they are
  read: setup-time docs (read once during project creation), startup-
  time docs (read at PM chat startup each session), and regular
  workflow docs (read during active development phases). Design file
  organization to match these access patterns.

- **Best use of RAG.** For tools and workflows that support RAG
  (Claude Desktop app, MCP integrations), the design should consider
  which documents benefit from RAG indexing vs. direct read, and
  structure content accordingly.

- **PM Chat tool flexibility.** Keep options open for using either
  the CLI (Claude Code, Codex, Gemini) or the Desktop app (Claude
  Projects) for PM Chat. The design must not assume one tool or
  lock out the other.

- **Seamless BD integration.** BD-044, BD-045, and BD-046 must be
  designed as a coherent whole, not three independent changes that
  happen to share a version number. File structures, naming
  conventions, PM chat behaviors, and migration steps must be
  consistent across all three.

- **Rollback plan.** The migration guide must include rollback
  instructions. Any destructive operation (replacing PROMPT-TEMPLATES.md
  with a directory, restructuring prompt files) must create a backup
  of what it replaces. A developer who encounters problems after
  migration must have a documented path back to v9.x.

- **Incremental testability.** Each implementation stage must leave
  the pack in a working state that can be tested independently before
  moving to the next stage. If BD-045, BD-046, and BD-044 are
  implemented sequentially, the pack must be functional after each
  one — not only after all three are complete.

---

## Part 8 — V9 Lessons Learned

*Added by pack chat review, April 2026. These are patterns from v9
development and post-release patches that v10 should avoid repeating.*

1. **Skills distribution design changed twice.** Added to bootstrap.sh
   during the v9.0 audit, then reversed in v9.x. Skills are now
   distributed once at project creation via QUICKSTART.md. Lesson:
   decisions about where setup work happens (one-time vs. repeated,
   script vs. manual) need explicit upfront justification with a clear
   rationale for why the work belongs at that lifecycle stage.

2. **agent-run.sh Gemini invocation was designed from incomplete
   understanding of the CLI.** The initial design used `--agent` (a
   flag that doesn't exist in Gemini CLI) and Plan Mode (which blocks
   all command execution). Both required post-release fixes. Lesson:
   tool-specific behavior must be verified against actual tool
   documentation before committing to a design. Do not extrapolate
   from one tool's behavior to another.

3. **GEMINI.md inline agent definitions were wrong from v9.0.**
   All 16 Gemini agent roles were defined inline in GEMINI.md instead
   of as native `.gemini/agents/*.md` files. This required the full
   BD-043 rework. Lesson: the trinity rule (structural parity across
   tools) needs to be validated against each tool's actual file system
   conventions, not just conceptually.

4. **V9-DESIGN.md verification checklist became stale.** The
   checklist said "bootstrap.sh must distribute skills" — which was
   later reversed. Historical design records that contain prescriptive
   guidance can mislead future maintainers if not updated when
   decisions change. Lesson: when a design decision is reversed,
   update the original design record's verification checklist, not
   just the operational docs.

5. **Maintenance-docs stale references were missed in initial audits.**
   V9-DESIGN.md and V9-AUDIT-REPORT.md had stale references to
   bootstrap.sh distributing skills that were initially dismissed as
   "historical records that don't need updating." They did need
   updating. Lesson: every doc audit must include maintenance-docs,
   not just operational docs. Stale prescriptive guidance in any
   document is a defect.

---

## Part 9 — Token Budget Analysis Requirement

*Added by pack chat review, April 2026.*

The prompt template reorganization (CD-8) is justified partly by
token efficiency — the PM chat would read one small file instead of
the full 765-line PROMPT-TEMPLATES.md. This assumption should be
validated with a concrete analysis during the design pass:

- How many tokens does the PM chat currently consume at startup
  reading PROMPT-TEMPLATES.md?
- How many tokens does one per-agent prompt file consume?
- What is the net savings per prompt generation?
- Does the savings justify the migration complexity (replacing a
  monolith with a directory, rewriting PM chat file access patterns,
  updating pm-startup, writing a migration script to split the file)?

If the savings are marginal, the reorg might not justify the
complexity. If they are significant, that's evidence for the decision.
The analysis grounds the decision in data rather than assumption.

---

## Part 10 — Migration Testing Matrix

*Added by pack chat review, April 2026.*

OQ-14 lists what to test but not the combinations. The design doc
must define the test matrix along these dimensions:

| Dimension | Values |
|---|---|
| Project type | Swift-only, Python-only, Swift+Python, Swift+gRPC, existing project with no AI tools |
| Migration path | v9.x → v10.0, new project via init-project.sh, existing project via init-project.sh |
| PM chat tool | Claude Code CLI, Claude Desktop app, Codex CLI, Gemini CLI |
| Custom file state | No custom files, custom agents only, custom skills only, custom agents + skills |

Not every combination must be tested, but the matrix must be defined
so the verification plan can specify which combinations are critical
path and which are deferred or out of scope.

---

## Part 11 — Pack Development Agents and Skills

*Added by pack chat review, April 2026.*

### Problem (resolved)

The pack repo had no agent files and only one skill (pack-startup).
Pack development work relied entirely on ad-hoc pack chat sessions
with no structured agent roles.

### Resolution

Four pack-specific agents were created as a pre-v10 step, with agent
files in `.claude/agents/`, `.codex/agents/`, and `.gemini/agents/`
at the pack repo root:

- **pack-architect** — architecture and design decisions for pack
  changes. Understands pack structure, trinity rule, BD items,
  version management, migration infrastructure.
- **pack-planner** — implementation planning for pack changes.
  Understands sequencing constraints, file dependencies, commit
  planning.
- **pack-reviewer** — reviews pack changes before commit. Checks
  trinity rule compliance, stale references, cross-doc consistency.
- **pack-docs-researcher** — CLI tool documentation verification.
  Verifies Claude Code, Codex CLI, and Gemini CLI features against
  official docs before design decisions are committed.

Five general-purpose skills were copied from `project-template/skills/`
to each tool's skill directory (not read from project-template at
runtime): `planning`, `architecture-review`, `documentation`, `review`,
`dependency-intake`.

PACK-AGENTS.md was updated with the full agent roster, invocation
commands (sub-agent via Task tool and separate terminal sessions),
and delegation guidance. PACK-CHAT.md received a delegation
behavioral rule.
