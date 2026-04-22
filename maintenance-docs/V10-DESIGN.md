# V10-DESIGN.md — AI Agent Config Pack v10 Design Document

---

## Part 0 — Status

| Field | Value |
|---|---|
| Status | **APPROVED** |
| Assembled | 2026-04-21 |
| Approved | 2026-04-21 |
| Author | pack-architect (assembly) + pack chat (writing) |
| Approved by | David Shane |
| Supersedes | `maintenance-docs/V10-PREDESIGN.md` |
| Review rounds | 5 (step-12-review-report through step-12-review-report-v5) |

### How to use this document

This is the sole authoritative design input to Phase 3 (implementation planning)
for v10.0. A reader who has never seen the working-document reports in
`maintenance-docs/v10-working/` can understand the full v10 design from this
file alone. Working-document reports become historical; this document is the
authority.

- **Parts 1–2** — why v10 exists and the approved decisions (former CDs).
- **Parts 3–7** — per-BD design sections with integration points called out.
- **Parts 8–10** — cross-cutting touch-point inventory, testing matrix,
  verification plan.
- **Parts 11–13** — V9 lessons carried forward, implementation sequence
  outline, and open items explicitly deferred.
- **Appendix A** — Design-requirement-to-section cross-reference.

Scope. Every Candidate Decision (CD-1 through CD-13) from V10-PREDESIGN Part 2
is carried into Part 2 as an Approved Decision. Every Open Question (OQ-1
through OQ-14) is either resolved in Parts 3–10 or listed in Part 13. Every
Design Requirement in V10-PREDESIGN Part 7 is addressed with a named section;
the cross-reference is in Appendix A.

---

## Part 1 — Why v10 Exists

v10 addresses three problems together because their solutions overlap on the
same files, and separating them would force multiple migration passes through
the same project state.

### Problem 1 — No structured mechanism for custom agents and skills

A project that needs a specialized agent or skill not in the pack has no
supported path. V9-DESIGN.md Decision 7 acknowledges project-level
customization but provides only a 6-step manual checklist with a warning
label. A developer who adds a custom agent directly to `.claude/agents/`
without PM chat involvement creates a file the PM chat cannot route to and
cannot include in generated prompts. The result is silent failure: the agent
exists on disk but is invisible to the workflow. Pack upgrades compound this
— the v9-era migration pattern uses `rm -rf .claude/agents/ && cp -r`, which
destroys any custom files. No preservation mechanism exists.

### Problem 2 — Prompt templates are monolithic and unassociated

`supporting-docs/PROMPT-TEMPLATES.md` is ~741 lines covering 14 templates.
PM-chat-internal instructions and agent-specific prompts are mixed in one
file. The PM chat reads the entire document when it needs any single template.
Agents with multiple prompt variants (coder has three) have all variants in
the same undifferentiated document. Custom agents from Problem 1 have no
natural home for their prompt templates.

### Problem 3 — Project onboarding and setup have structural gaps (BD-044, BD-045)

- **BD-044.** `QUICKSTART.md` assumes a new project started from scratch.
  A developer adding the pack to an existing project with no AI tooling has
  no supported path. The current setup requires manual `cp -r`, manual skill
  distribution, no detection of existing project state, and no PM chat prompt
  generated at the end.
- **BD-045.** The capabilities design pattern appears in the pack only as an
  approved escape hatch for LSP compliance. It is never defined, never
  explained, and never presented as a design tool to reach for proactively
  during architecture. Architecture guidance and skills must champion it
  alongside LSP as a first-class pattern.

These three problems ship in one major version because BD-044 touches the
same migration infrastructure as Problems 1 and 2, and BD-045 touches the
same context files and skills that custom agent support also updates.
Batching avoids multiple migration passes through the same files.

### v9.x compatibility

v10 preserves all v9.x functionality unless explicitly noted otherwise.
The following v9.x capabilities are preserved:

- **Developer choice of PM chat tool.** Claude Code CLI, Claude Desktop
  app, Codex CLI, and Gemini CLI all remain supported for PM chat and
  agent work (Part 5 §5.1, Part 9 §9.6).
- **Tool interchangeability.** Developers can use Claude, Codex, and
  Gemini interchangeably for any task per the Phase routing table.
  Custom agents extend the same routing table (Part 5 §5.6).
- **PACK-FEEDBACK.md mechanism.** The PM chat observes agent performance,
  records feedback, and delivers to the Pack Chat at workflow boundaries
  — unchanged (Part 7 §7.8 skill-gap tracking uses the same mechanism).
- **All v9.x agent roles (16).** The pack roster (Part 5 §5.3) enumerates
  all 16 v9.3 agents; none are removed.
- **All v9.x skills (30).** Skill directories are updated in place; no
  skill is removed.
- **Desktop Commander / filesystem MCP.** Recommended for Claude Desktop
  PM chat (Part 4 §4.1). The pack does not require it — Project knowledge
  upload remains viable without it.
- **mcp-local-rag for large-file RAG.** METHODOLOGY.md RAG freshness
  check is retained (Part 4 §4.7). Only the PROMPT-TEMPLATES.md RAG
  ingest is dropped (the monolith no longer exists).

**Known per-tool limitations (documented, not silent):**

- Codex CLI hooks only fire for the Bash tool — file-edit hooks do not
  exist (Step 2 C-3). Detection of manually added files relies on PM
  chat startup and phase-gate scans, not hooks.
- Claude Desktop without filesystem MCP requires manual file upload for
  Project knowledge; the MCP is recommended but not required.
- Codex skill loading with `x-` prefix is not yet verified from official
  docs (Part 13 §13.1 — deferred, with empirical test planned).
- Gemini CLI hook model was not fully verified in the v10 design pass
  (Part 13 §13.2 — deferred, non-blocking).

---

## Part 2 — Approved Decisions

Every Candidate Decision in V10-PREDESIGN Part 2 is confirmed or revised below
as an Approved Decision (AD). Each entry records the decision, its rationale,
and rejected alternatives, following the V9-DESIGN.md Decisions 1–9 format.

### AD-1 — `x-` prefix for all custom files (uniform across tools)

**Decision.** Custom agents, skills, and prompt files are distinguished from
pack files by an `x-<name>` filename prefix. The prefix is uniform across
Claude Code, Codex, and Gemini at the filename level and in the Codex agent
TOML `name =` field (Codex accepts the hyphenated form; confirmed by Step 2
smoke test, resolving Step 2 Contradiction C-2).

Concrete forms:

| Surface | Custom file pattern | Identifier value |
|---|---|---|
| Claude agent | `.claude/agents/x-<name>.md` | YAML `name: x-<name>` |
| Codex agent | `.codex/agents/x-<name>.toml` | TOML `name = "x-<name>"` + `description = "..."` (both required; Codex silently ignores agents missing either field) |
| Gemini agent | `.gemini/agents/x-<name>.md` | YAML `name: x-<name>` |
| Skill (each tool) | `{.claude,.codex,.gemini}/skills/x-<name>/SKILL.md` | YAML `name: x-<name>` |
| Prompt | `docs/pack/prompts/x-<name>.md` | YAML `agent: x-<name>` |

`<name>` matches `^[a-z][a-z0-9-]*$`. The `x-` namespace is **reserved for
project customizations**; the pack itself never ships an `x-` file. A new
pack CI check (Part 10 §10.1 V-CI-05/06) enforces this.

**Rationale.** Custom files must coexist with pack files in each CLI's
designated directory (the tools only scan their own directory — there is no
alternative location). A filename marker is the single mechanism that makes
the classification obvious on disk and trivial for the migration script to
preserve. Uniform hyphenation across the three tools removes an entire class
of cross-tool lookup bugs and matches the existing convention (all pack
agents use the same stem across tools).

**Alternatives rejected.**
- *No prefix, track customization in a separate registry file.* Rejected —
  visibility on disk is required for developers inspecting the directories,
  and preservation during migration is far simpler when the filename itself
  carries the classification.
- *Different identifier forms per tool* (e.g., `x-foo.md` in Claude and
  Gemini but `name = "x_foo"` inside Codex TOML). Rejected — the smoke test
  made the fallback unnecessary, and asymmetry would force a per-tool
  identifier-translation layer the PM chat would have to maintain.

### AD-2 — Custom files follow the same structure as pack files

**Decision.** "Identical structure" means identical to each tool's pack-file
format in that tool, not literally identical across tools. Each tool has its
own required structure:

- **Claude:** YAML frontmatter (`name`, `description`, `tools`) + markdown body.
- **Codex:** TOML with `name`, `description` (both required — Codex silently
  ignores agents missing either), `model`, `approval_policy`, `sandbox_mode`,
  `developer_instructions` (triple-quoted string).
- **Gemini:** YAML frontmatter (`name`, `description`, `model`, `temperature`,
  `max_turns`) + markdown body.

The PM chat's creation workflow produces the tool-native form for each;
custom files pass the same per-tool structural checks that pack files do (the
only thing keeping them out of the pack roster is the `x-` filename).

**Rationale.** Each tool loads the file natively from disk. A "pack canonical"
translation layer on top of three tool files would add a step the tools
themselves never run. The PM chat already performs the translation once at
creation; that is the right place for it to live.

**Alternatives rejected.**
- *A single "pack canonical" agent spec translated into three tool forms at
  consume time.* Rejected per V9 Lesson 2 — do not extrapolate across tools.

### AD-3 — PM chat is the primary creation mechanism (OQ-7 resolved)

**Decision.** The PM chat is the only *supported* creation mechanism for
custom agents and skills. Manual addition is not prevented by any enforcement
mechanism, but manual additions are *unsupported* and are visible only after
the PM chat's detection scan classifies them and offers to complete
registration at next startup or phase gate.

The "detect-and-offer-to-register" behavior is the sole documented escape
hatch. No parallel manual procedure is published.

**Rationale.** Two paths to the same outcome double the maintenance surface
and historically produce inconsistent behavior when one path is revised and
the other is not (V9 Lesson 1). A single path keeps the lifecycle story
uniform. The "Codex-only, offline, or knowledgeable developer" case in OQ-7
is handled by the same flow: the developer drops a file, the PM chat's first
run classifies and registers it.

**Alternatives rejected.**
- *Enforce PM-chat-only creation via a hook that blocks edits outside the
  chat.* Rejected — no cross-tool-consistent way to do it (Step 2
  Contradiction C-3: Codex does not fire file-edit hooks; Claude Code has
  them, but enforcing via them alone would build three asymmetric
  enforcement layers — V9 Lesson 2).
- *Two documented paths (chat-driven and manual procedure).* Rejected —
  V9 Lesson 1 pattern.

### AD-4 — Three creation paths for custom agents

**Decision.** CD-4 is confirmed unchanged. The PM chat supports three
creation paths, all converging on four approval gates (G-design, G-files,
G-registration, G-commit):

1. **Describe-driven.** Developer describes the agent; PM chat asks
   clarifying questions and drafts all artifacts.
2. **One-tool-format seed.** Developer provides one tool's agent file; PM
   chat translates to the other two formats and drafts the prompt.
3. **Existing-file adoption.** Developer provides a file not in pack
   conventions; PM chat reviews, rewrites to conventions, then produces the
   other two forms plus the prompt.

Per custom-agent request, the PM chat produces six or nine artifacts (three
agent files, prompt file, PLATFORM-SKILLS.md row, trinity routing-table
rows; plus three SKILL.md files if a custom skill is involved). The PM chat
does **not** edit `.codex/config.toml` — no per-agent registration entry
exists in documented Codex (Part 5 §5.4 resolves OQ-2).

**Rationale.** The three paths cover the realistic starting states a
developer arrives with. Four approval gates preserve incremental testability
— a developer who aborts at any gate leaves the project in a pre-gate state
cleanly revertable with `git restore`.

**Alternatives rejected.** None within CD-4's scope.

### AD-5 — Migration preserves `x-` files by in-place skip

**Decision.** The v9.3 → v10.0 migration preserves `x-` files using an
in-place skip mechanism, not temp-move-and-restore, and not a manifest. The
migration script replaces pack-owned files by removing only the pack-roster
set from each scanned directory and copying the new pack template — it
never does a wholesale `rm -rf` on any directory that can contain `x-`
files. Files that are neither pack nor `x-` prefixed are **preserved in
place** and flagged in the migration report for PM-chat-driven adoption,
removal, or deferral post-migration (Procedure 5.4).

Scanned directories: the seven from AD-10 §Detection directories.

**Rationale.** In-place skip cannot strand custom files (they never leave
their destination), has one write side (replace pack files only), and
yields a clean `git status` audit trail. Temp-move-and-restore has two write
sides and can leave custom files in a temp directory on interrupt.

**Alternatives rejected.**
- *Temp-move-and-restore.* Rejected — two failure modes (stranded files,
  partial restore) that in-place skip does not have.
- *Wholesale `rm -rf .claude/agents/ && cp -r ...` (v8→v9 pattern).*
  Rejected — destroys custom files. v10 cannot use it.

### AD-6 — Custom skills load the same way as pack skills

**Decision.** A custom skill with `SKILL.md` in each of the three tool
skill directories is loaded via the identical prompt-instruction mechanism
as every pack skill (the PLATFORM-SKILLS.md Step 3 block: `Load the
following skills for this task: …`). No separate loading mechanism exists.

Per Step 2 findings: Claude Code picks up new skills via live change
detection within already-watched directories; Gemini CLI uses progressive
disclosure at session start with `/skills reload` runtime refresh; Codex
skill loading is consistent with the other two (targeted verification
remains as a Phase 4 follow-up, recorded in Part 13).

**Rationale.** One loading mechanism keeps PLATFORM-SKILLS.md as the PM
chat's single lookup target for "what does this agent need."

**Alternatives rejected.**
- *Auto-include custom skills by scanning `x-` directories at prompt time.*
  Rejected — automatic inclusion defeats the "not visible until registered"
  property of AD-3.

### AD-7 — PLATFORM-SKILLS.md gains `## Custom agents` and `## Custom skills` sections

**Decision.** Two new sections, not one, because a project may have custom
agents without custom skills, or vice versa. Both headers land immediately
after `## Full skill inventory`. The sections are **project-owned**:
content is preserved across pack upgrades by the migration splice rule
(Part 6 §6.6).

Column specs are given in Part 5 §5.2 (exact headers, columns, and example
rows). A project with no customizations carries the headers with the
placeholder text `*No custom X defined for this project.*`.

**Rationale.** PLATFORM-SKILLS.md is already the PM chat's prompt-time
lookup target for agent/skill mapping. One file answers all "what's
available" questions uniformly.

**Alternatives rejected.**
- *Separate file for custom entries* (`docs/pack/CUSTOM.md`). Rejected —
  adds a second read and maintenance surface.

### AD-8 — Prompt templates reorganized into per-agent files (CD-8 confirmed with corrections)

**Decision.** `supporting-docs/PROMPT-TEMPLATES.md` is replaced by a
directory at `project-template/docs/pack/prompts/` containing ten per-agent
prompt files plus one authoring-guidance file. The file list (Part 4 §4.2
for full detail):

```
docs/pack/prompts/
    coder.md              (variants: standard, fix-cycle)        from T2, T4
    reviewer.md           (variants: standard)                    from T3
    tester.md             (variants: standard)                    from T5
    planner.md            (variants: standard)                    from T7
    docs-researcher.md    (variants: standard)                    from T6
    architect.md          (variants: mid-phase)                   from T4b
    grpc-schema.md        (placeholder — zero variants)
    repo-ops.md           (placeholder — zero variants)
    auditor.md            (variants: standard)                    from T9
    pm-chat.md            (variants: kickoff, backlog-status-     from T1, T8,
                                   update, generate-setup,              T13, T14
                                   generate-agent-kickoff)
    PROMPT-AUTHORING.md   (authoring guidance, per-agent exceptions
                           table, self-check rule; points at
                           METHODOLOGY.md for full "Prompt
                           Authoring Principles")
```

**Two corrections to the CD-8 proposal.**
1. Mid-Phase Architect (T4b) is reassigned from `coder.md` to `architect.md`
   — it is an architect-agent prompt (Part 4 §4.2).
2. `architect.md`, `grpc-schema.md`, and `repo-ops.md` receive zero-variant
   placeholder files to preserve the "one file per agent" rule that AD-4's
   creation workflow and AD-5's migration both depend on (Part 4 §4.2).

**One rename incorporated from Step 11 assembly notes.** The pointer file
at the top of the directory is named `PROMPT-AUTHORING.md`, not `README.md`.
It carries the "How to use these templates" guidance, the per-agent
exceptions table, and the self-check rule directly, plus a pointer to
METHODOLOGY.md for the full Prompt Authoring Principles. Uppercase name
distinguishes it from the per-agent lowercase files; the filename is
descriptive where a generic `README.md` would not be.

**No orphaned templates.** All 14 templates in the v9.3 monolith have
destinations in the split (Part 4 §4.1); T10–T12 are already marked
superseded in the monolith and remain so as a trailing note in
`auditor.md`. After redistribution, zero content remains in the monolith —
deletion is correct.

**Token budget result.** The reorganization reduces per-prompt-generation
token cost by 76–87% on every non-RAG PM chat surface (Claude Code CLI
without RAG, Claude Desktop + filesystem MCP, Codex CLI, Gemini CLI). The
Claude Code CLI + mcp-local-rag case and the Claude Desktop + Project
knowledge case improve qualitatively (RAG chunk boundaries align with
agent scope); exact token savings are workflow-dependent. Per V10-
DESIGN-PROCESS-PLAN Step 4 decision rule, savings ≥ 30% on every non-RAG
surface justifies the reorganization on efficiency grounds alone; CD-9
and per-agent maintenance localization reinforce it structurally.

**Rationale.** The monolith's problems (read cost, lack of custom home,
non-localized edits) all resolve when prompts are one file per agent.
Per-agent files are directly read on demand at the PM chat's prompt-
generation moment — the single access point for prompts.

**Alternatives rejected.**
- *Keep the monolith.* Rejected — fails token math, fails OQ-3, fails
  OQ-11 localization.
- *One file per variant* (`coder-standard.md`, `coder-fix-cycle.md`).
  Rejected — trebles the file count without reducing per-generation token
  cost.
- *Per-agent-per-variant nested directories.* Rejected — adds a directory
  level for the migration to handle, no benefit.

### AD-9 — Custom agent prompts live in the same `prompts/` directory

**Decision.** Custom agent prompt files: `docs/pack/prompts/x-<name>.md`.
Same format as pack prompt files (AD-10 §Format spec). No separate location
for custom prompts.

**Rationale.** Uniform location and format make the PM chat's prompt-lookup
workflow identical for pack and custom agents. A separate custom-prompts
directory would force every consumer to check two paths.

**Alternatives rejected.**
- *Separate `docs/pack/custom-prompts/` directory.* Rejected — reintroduces
  the "where do I look?" problem.

### AD-10 — BD-044 is v10 scope

**Decision.** BD-044 (init-project.sh, QUICKSTART router, existing-project
onboarding) ships in v10.0. Its migration automation overlaps with the v10
migration script and must be built together.

Deliverables (Part 7 details):
- `scripts/init-project.sh` — detection pass, preview-and-confirm, new- and
  existing-project paths, end-of-run PM chat prompt.
- `scripts/lib/detect.sh` — shared detection library (OQ-5 resolved: two
  scripts + shared library rather than one script with mode flags).
- `QUICKSTART.md` rewritten as a ~30-line three-path router (new project →
  SETUP-NEW.md; existing → SETUP-EXISTING.md; upgrade →
  MIGRATION-vN-to-vM.md).
- `supporting-docs/SETUP-NEW.md` — new-project procedural guide.
- `supporting-docs/SETUP-EXISTING.md` — existing-project procedural guide
  with preview walkthrough and existing-docs pointer procedure.
- Migration guide naming convention documented (authoritative in
  `README.md` Repository Layout section).

**Detection directories.** The seven directories that the PM chat detection
scan, migration preservation, and init-project "already configured" stop
condition all consult:

1. `.claude/agents/*.md`
2. `.codex/agents/*.toml`
3. `.gemini/agents/*.md`
4. `.claude/skills/*/SKILL.md`
5. `.codex/skills/*/SKILL.md`
6. `.gemini/skills/*/SKILL.md`
7. `docs/pack/prompts/*.md`

One list shared by all three mechanisms; maintained at Part 5 §5.8.

**Rationale.** Batching BD-044 with BD-046 migration work avoids two
separate migration passes through the same files and consolidates the
shared detection surface into one shared library.

**Alternatives rejected.**
- *Ship BD-044 in v9.4 as a minor.* Rejected per V10-PREDESIGN CD-10 and
  Step 1 G1 confirmation — its shared detection with the migration script
  is structural, not incremental.

### AD-11 — BD-045 is v10 scope

**Decision.** BD-045 (capabilities design pattern alongside LSP) ships in
v10.0. Its changes touch the same trinity files, architecture skills, and
auditor-architecture agent files that v10 updates for custom agent support.
Batching avoids a separate minor version commit across the same files.

Deliverables: concrete draft text for all nine BD-045 locations (full
content in Part 3), plus the placeholder template for future language
skills.

**Rationale.** Trinity-file ordering and commit sequencing must not leave
BD-045's LSP-adjacent edits half-present alongside BD-046's phase-routing
and document-location edits. Single-version delivery allows coordinated
commits (Part 8 §8.4).

**Alternatives rejected.**
- *Ship BD-045 in v9.4 as a minor.* Rejected per Step 1 G1 confirmation —
  collides with BD-046 trinity-file edits.

### AD-12 — v10.0 is the target version

**Decision.** The combined scope (BD-044 + BD-045 + BD-046 + migration +
init-project + custom-file mechanism) warrants a major version.
`supporting-docs/MIGRATION-v9-to-v10.md` ships with v10.0; the automatable
option is `scripts/migrate-v9-to-v10.sh` with a paste-ready AI CLI prompt
pattern (Part 6 §6.9) matching the MIGRATION-v8-to-v9 convention.

**Rationale.** File-structure changes (prompt reorganization, new
`docs/pack/prompts/` directory, new `scripts/lib/` directory, new
`supporting-docs/SETUP-*.md` pair, new `## Custom agents`/`## Custom
skills` sections in trinity and PLATFORM-SKILLS.md) are a breaking change
with respect to migration tooling — projects cannot upgrade with a simple
file diff.

**Alternatives rejected.** None.

### AD-13 — Latest v9.3 is the only migration baseline

**Decision.** `scripts/migrate-v9-to-v10.sh` supports exactly one source
baseline: v9.3 (git tag `v9.3`). Pre-flight invariants (Part 6 §6.3)
reject any other state. If a project is on v9.0/v9.1/v9.2, the developer
upgrades to v9.3 first using existing minor-version refresh; older majors
(v8.x and earlier) apply `MIGRATION-v8-to-v9.md` first.

**Rationale.** V10-PREDESIGN Part 6 documents that all existing projects
are on the latest v9.x; the floating `v9` tag points at v9.3. One baseline
is simpler to test, document, and support.

**Alternatives rejected.**
- *Support v9.0/v9.1/v9.2 → v10.0 directly.* Rejected — per-source-version
  branching logic that adds risk without covering a real user scenario.

---

## Part 3 — Design: BD-045 Capabilities Pattern

Concrete, ready-to-use draft text for all nine BD-045 locations. An
implementer applies these drafts in Phase 4 without further design-level
decisions.

### 3.1 Design principles

- **LSP is required; capabilities are a recommended best practice.** LSP
  is a required coding practice. The capabilities pattern is a recommended
  best practice — championed proactively during architecture, not mandated.
  If the project's architecture doesn't support it naturally or the developer
  explicitly opts out, that is valid. Neither is a prerequisite for the other,
  and neither is the motivation for the other. They work well together when
  both are present, but absence of capabilities is a recommendation, not a
  defect. The BD-045 BACKLOG entry's original "required" language is
  superseded by this design decision and will be updated when BD-045 is
  resolved at v10.0 ship.
- **Two complementary forms.** Value-based (bitmask / flag set / enum set)
  and interface-based (small focused interface adopted only when
  supported) are always named as a pair.
- **Language-agnostic in trinity files and in architecture-review;
  language-specific in per-language skills.**
- **Trinity symmetry.** CLAUDE.md / AGENTS.md / GEMINI.md contain the
  identical section and anti-pattern bullet; no tool-specific deviation is
  justified for this content.
- **Proactive, not reactive.** Every draft instructs the reader to reach
  for the pattern during design, not only when fixing an LSP violation.

### 3.2 Locations 1–3 — Trinity files

#### New section (identical in all three files)

**Placement.** Insert immediately after `## Liskov Substitution Principle`
and before `## Dependency intake policy` (CLAUDE.md / GEMINI.md) or
`## Dependency intake` (AGENTS.md).

**Section text (copy verbatim, identical in all three files):**

```markdown
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
and queryable, eliminating the need for callers to discover
limitations through runtime surprises. The specific language mechanism
varies (compile-time or runtime conformance checks, structural
subtyping, flag values, enum sets, etc.), but the design intent is
consistent across any typed system.

**Relationship to LSP.** LSP is a required coding practice — every
method declared in an interface must have a meaningful implementation
in every conforming type. The capabilities pattern is a recommended
best practice — an architectural tool for making supported behaviors
explicit and queryable. Neither is a prerequisite for the other, and
neither is the motivation for the other. They work well together when
both are present, but this is a benefit of using both — not a
dependency between them. If the capabilities pattern does not fit the
project's architecture or the developer opts out, that is valid.
```

#### Anti-pattern bullet (identical in all three files)

**Placement.** Append as the final bullet of the universal (non-
conditional) anti-patterns list under `## [CONDITIONAL] Anti-patterns —
never introduce these`, before the `[PLATFORM_ANTIPATTERNS]` placeholder.

**Bullet text (copy verbatim):**

```markdown
- Branching on concrete types to discover what an abstraction supports, instead of querying a capability value or interface.
```

**No tool-specific deviations are justified** for this content — every
sentence applies identically to work under any of the three CLIs.

### 3.3 Location 4 — apple-architecture-core/SKILL.md

**Placement.** Insert after `## Protocol abstractions` (current rules 8–10)
and before `## Actor isolation and state` (current rules 11–13). Existing
rules 11–23 shift to 15–27.

**Section text (copy verbatim, then renumber subsequent rules):**

```markdown
## Capabilities pattern

11. Make what a type supports explicit and queryable. Callers do not
discover unsupported operations through `fatalError`, `throw`, or
`switch` on concrete types. Reach for this pattern proactively during
architecture — not only when fixing an LSP violation. LSP is required; the capabilities pattern is a recommended best practice.
Apply each on its own merits.

12. **Value-based form in Swift.** Expose supported operations as an
`OptionSet` (bitmask), a `Set<Enum>` of a focused operation enum, or a
frozen struct of `Bool` flags, exposed on the abstraction as a
read-only property. Validate capability compatibility at the
*composing* type's initializer — reject incompatible pairings at
construction time, not at call time. Example: a `Broker` protocol
declares `var capabilities: BrokerCapabilities { get }` where
`BrokerCapabilities` is an `OptionSet` (`.placeOrder`, `.cancelOrder`,
`.streamQuotes`, …). Callers check
`broker.capabilities.contains(.streamQuotes)` before invoking the
streaming call.

13. **Interface-based form in Swift.** Split behavior into small,
focused protocols. A type adopts only the protocols it genuinely
supports. Callers query with a downcast to the capability protocol
(`if let streaming = broker as? StreamingQuoteProvider { … }`), never
to the concrete type. Compose protocols via protocol inheritance or
generic constraints (`where Broker: StreamingQuoteProvider`). Do not
emulate capabilities by throwing from stub conformances — a type that
does not stream must not conform to `StreamingQuoteProvider` at all.

14. **Where capability validation belongs.** Initializers of the
composing type (account ⇠ broker, order router ⇠ broker, quote
aggregator ⇠ provider) reject incompatible pairings at construction
time. Call sites query capabilities only for behavior that legitimately
varies across conforming types — never as a substitute for
LSP-compliant method implementations.
```

### 3.4 Location 5 — python-best-practices/SKILL.md

**Placement.** Insert after `## Error handling` (current rules 10–13) and
before `## Tooling` (current rules 14–20). Existing rules 14–32 shift to
18–36.

**Section text (copy verbatim, then renumber subsequent rules):**

```markdown
## Capabilities pattern

14. Make what a type supports explicit and queryable. Callers do not
discover unsupported operations through `NotImplementedError`, silent
`pass`, `hasattr` probes, or `isinstance` branching on concrete types.
Reach for this pattern proactively during architecture — not only when
fixing an LSP violation. LSP is required; the capabilities pattern is a
recommended best practice. Apply each on its own merits.

15. **Value-based form in Python.** Expose supported operations as a
class-level attribute — an `enum.Flag` (bitwise capabilities), a
`frozenset[Operation]` over an `enum.Enum`, or a frozen
`@dataclass(frozen=True)` of boolean fields. Validate capability
compatibility in the composing type's `__init__` — raise early on
incompatible pairings, not at call time. Example: a `Broker`
`Protocol` declares `capabilities: ClassVar[BrokerCapability]` where
`BrokerCapability` is an `enum.Flag` (`PLACE_ORDER | CANCEL_ORDER |
STREAM_QUOTES | …`). Callers check
`BrokerCapability.STREAM_QUOTES in broker.capabilities` before
invoking the streaming call.

16. **Interface-based form in Python.** Split behavior into small
`typing.Protocol` classes (structural subtyping). A type satisfies
only the protocols whose behavior it genuinely implements. Use
`@runtime_checkable` on protocols only when a runtime check is
required at a boundary; prefer static `isinstance` with generic bounds
when the check is compile-time. Callers do
`if isinstance(broker, StreamingQuoteProvider): …`. A broker that does
not stream simply omits `stream_quotes` — it is not a
`StreamingQuoteProvider` by structural typing. Do not emulate
capabilities by raising `NotImplementedError` from stub implementations.

17. **Where capability validation belongs.** The composing class's
`__init__` (account ⇠ broker, router ⇠ broker, service factory)
raises a domain error on incompatible pairings. `try/except
NotImplementedError` at call sites, and `hasattr(obj, "method")`
probing, are anti-patterns — they are not substitutes for a capability
query. Never raise `NotImplementedError` for operations that could
instead be gated by a capability check.
```

### 3.5 Location 6 — Placeholder template for future language skills

When a new language skill is created (`swift-best-practices`,
`cpp-language`, `c-language`, `objc-language`, or any later language),
it includes a capabilities-pattern section built from this template.
Substitute the five `<LANGUAGE-SPECIFIC>` slots and renumber.

```markdown
## Capabilities pattern

N1. Make what a type supports explicit and queryable. Callers do not
discover unsupported operations through exceptions, silent no-ops, or
branching on concrete types. Reach for this pattern proactively during
architecture — not only when fixing an LSP violation. LSP is required; the capabilities pattern is a recommended best practice.
Apply each on its own merits.

N2. **Value-based form in <LANGUAGE>.** <LANGUAGE-SPECIFIC: name the
idiomatic mechanism for a flag-set, bitmask, or enum set in this
language. Give one concrete example of a capability value declared on
an abstraction and one example of a caller querying it.> Validate
capability compatibility at association or initialization time —
reject incompatible pairings before the capability is needed.

N3. **Interface-based form in <LANGUAGE>.** <LANGUAGE-SPECIFIC: name
the idiomatic mechanism for small, focused interfaces, traits,
protocols, or structural types in this language. Give one concrete
example of a type adopting a capability interface and one example of a
caller querying for it.> Types that do not support a behavior do not
advertise the interface — no silent no-ops, no unconditional throws.

N4. **Where capability validation belongs.** <LANGUAGE-SPECIFIC:
identify the typical composing-type construction point for this
language — constructor, initializer, factory, builder.> Call sites
query capabilities only for behavior that legitimately varies across
conforming types — never as a substitute for LSP-compliant method
implementations.
```

### 3.6 Location 7 — architecture-review/SKILL.md

**Placement.** Insert after `## Abstraction quality` (current rules 11–13)
and before `## Navigation and control flow` (current rule 14). Existing
rules 14–15 shift to 18–19.

**Section text (copy verbatim, then renumber):**

```markdown
## Capabilities pattern

14. Verify the code reaches for the capabilities pattern proactively —
not only when fixing an LSP violation. Capabilities and LSP are
independent practices — LSP is required, capabilities are recommended.
Both should be present where each applies; absence of capabilities is
a finding, not a defect. A codebase that applies both avoids a wide class of runtime
surprises — callers know what an abstraction supports before invoking
it, and every declared interface method is meaningfully implemented.

15. Flag absence of any capability mechanism in any abstraction whose
conforming types have variable supported operation sets. If two or
more conforming types differ in what operations they support, some
form of capability query must exist for callers to check before
invoking — either value-based (enum set, bitmask, flag struct) or
interface-based (small focused protocol, trait, or structural type).
Loaded language skills supply the idiomatic mechanism for this
language.

16. Flag interface implementations that throw "not supported" (or an
equivalent runtime error, e.g. `NotImplementedError`, `fatalError`,
silent no-op) for operations that could instead be gated by a
capability check. The conforming type should either implement the
operation meaningfully (LSP), not declare the method (interface-based
capability), or the caller should gate the call upstream with a
capability query (value-based).

17. Flag caller code that branches on the concrete type behind an
abstract reference to discover what the abstraction supports. Callers
must use the capability mechanism — query a capability value, or
conditionally downcast to a capability protocol — never inspect the
concrete type.
```

### 3.7 Locations 8–10 — auditor-architecture agent (all three tool files)

**Placement.** In each of the three auditor-architecture files, insert a
new scope bullet in the Scope list immediately after the existing
`LSP compliance` bullet and before the `Observability infrastructure`
bullet. Capabilities and LSP stay as two separate bullets — BD-045's
"independent practices" language — so a finding from one
category is not miscategorized as the other.

**Claude markdown file (`project-template/.claude/agents/auditor-architecture.md`) and Gemini markdown file (`project-template/.gemini/agents/auditor-architecture.md`) — identical text:**

```markdown
- **Capabilities pattern adherence** — abstractions whose conforming
  types have variable supported operation sets but expose no
  capability mechanism (value-based flag set or interface-based query);
  "not supported" throws or silent no-ops that indicate a missing
  capability gate rather than a legitimate LSP-compliant
  implementation; caller code that interrogates the concrete type
  behind an abstract reference instead of querying a capability.
  LSP is required; capabilities are recommended — file capability
  findings under this bullet, not under LSP.
```

**Codex TOML file (`project-template/.codex/agents/auditor-architecture.toml`).** Insert inside the
`developer_instructions = """…"""` block in the `Scope (per audit-
methodology rule 15):` list, plain-bullet style without markdown bold
(matches the surrounding block's existing style):

```
- Capabilities pattern adherence — abstractions whose conforming types have variable supported operation sets but expose no capability mechanism (value-based flag set or interface-based query); "not supported" throws or silent no-ops that indicate a missing capability gate rather than a legitimate LSP-compliant implementation; caller code that interrogates the concrete type behind an abstract reference instead of querying a capability. LSP is required; capabilities are recommended — file capability findings under this bullet, not under LSP.
```

The Codex formatting deviation (no markdown bold, single-paragraph inside
a TOML triple-quoted string) matches the existing trinity pattern already
present in these three auditor files. No semantic deviation.

### 3.8 Trinity symmetry audit (BD-045)

| Content | Symmetry |
|---|---|
| `## Capabilities pattern` section (trinity files) | Byte-identical across CLAUDE.md / AGENTS.md / GEMINI.md |
| Anti-pattern bullet (trinity files) | Byte-identical across the three |
| `auditor-architecture` scope bullet (Claude, Gemini) | Byte-identical markdown |
| `auditor-architecture` scope bullet (Codex) | Semantically identical; plain-bullet TOML-embedded formatting |

No other tool-specific deviation is required or proposed.

### 3.9 LSP-vs-capabilities relationship — exact language

Wherever the drafts above state the relationship, LSP remains required.
The capabilities pattern remains recommended — not required — and is
always presented as a first-class proactive design tool rather than an
escape hatch. The recommended-not-required framing is never softened to
"required," and never exaggerated to "mandatory." Absence of
capabilities is a recommendation/finding, not a defect. The developer
may opt out if the architecture does not support it naturally.

### 3.10 BD-045 integration with BD-046 trinity edits

BD-045 adds content in the LSP section and the anti-patterns list. BD-046
adds content in the Document-locations table row for `docs/pack/` and in
a new `### Custom agents` sub-section of the Phase routing table. These
are four different sections of each trinity file. No content collision.

Commit sequencing (Part 12) coordinates the edits so no trinity file is
left with half of BD-045's additions and half of BD-046's.

---

## Part 4 — Design: Prompt Template Reorganization

Addresses V10-PREDESIGN CD-8 (prompt reorg), OQ-4 (pm-startup after reorg),
OQ-9 (directory name and non-prompt content), and OQ-11 (per-agent file
format). Incorporates V10-PREDESIGN Part 9 (token budget analysis).

### 4.1 Token budget analysis

**Method.** `wc -w` × 1.3 proxy against the v9.3
`supporting-docs/PROMPT-TEMPLATES.md` (741 lines, 4,986 words; ~6,482
proxy tokens total).

**Per-segment measurements** (line ranges, words, proxy tokens):

| Segment | Lines | Words | Proxy tokens | Destination |
|---|---:|---:|---:|---|
| Header / How-to-use / Prompt Authoring Principles | 1–77 | 646 | 840 | Hoisted to METHODOLOGY.md (already the canonical source); short pointer in `PROMPT-AUTHORING.md` |
| T1 — PM Chat Kickoff | 79–129 | 310 | 403 | `pm-chat.md ## Variant: kickoff` |
| T2 — Coder Standard | 131–209 | 589 | 766 | `coder.md ## Variant: standard` |
| T3 — Reviewer | 211–291 | 654 | 850 | `reviewer.md ## Variant: standard` |
| T4 — Fix Cycle | 293–375 | 591 | 768 | `coder.md ## Variant: fix-cycle` |
| T4b — Mid-Phase Architect | 377–422 | 325 | 423 | `architect.md ## Variant: mid-phase` (reassigned from coder) |
| T5 — Tester | 424–451 | 168 | 218 | `tester.md ## Variant: standard` |
| T6 — Docs-Researcher | 453–486 | 144 | 187 | `docs-researcher.md ## Variant: standard` |
| T7 — Planner | 488–511 | 137 | 178 | `planner.md ## Variant: standard` |
| T8 — BACKLOG/STATUS update | 515–570 | 341 | 443 | `pm-chat.md ## Variant: backlog-status-update` |
| T9 — Auditor | 572–632 | 421 | 547 | `auditor.md ## Variant: standard` |
| T10–12 — Superseded | 634–653 | 110 | 143 | Trailing note in `auditor.md` |
| T13 — Generate SETUP.md | 655–678 | 107 | 139 | `pm-chat.md ## Variant: generate-setup` |
| T14 — Generate AGENT_KICKOFF.md | 680–738 | 422 | 549 | `pm-chat.md ## Variant: generate-agent-kickoff` |
| Footer | 740–741 | 20 | 26 | Drop |
| **Total monolith** | **741** | **4,985** | **~6,482** | — |

**Per-generation savings** (tokens charged when the PM chat looks up one
agent's template):

| PM chat surface | v9 access | v10 access | Savings |
|---|---|---|---|
| Claude Code CLI (mcp-local-rag on monolith) | ~1,500 tokens RAG retrieval | 850–1,534 tokens direct read | ~10–40% + RAG ingest dropped |
| Claude Code CLI (direct read) | 6,482 tokens | 850–1,534 tokens | 76–87% |
| Claude Desktop + filesystem MCP | 6,482 tokens | 850–1,534 tokens | 76–87% |
| Claude Desktop + Project knowledge | RAG over 30 MB upload | RAG over directory of small chunks | Qualitative improvement (tighter chunk boundaries) |
| Codex CLI | 6,482 tokens | 850–1,534 tokens | 76–87% |
| Gemini CLI | 6,482 tokens | 850–1,534 tokens | 76–87% |

Per V10-DESIGN-PROCESS-PLAN Step 4 decision rule (≥30% savings justifies
on efficiency grounds alone; 10–30% requires structural enablement; <10%
requires structural justification only): ≥30% threshold met on every
non-RAG surface. Reorg justified on efficiency alone, with structural
enablement (AD-9 custom prompt placement; per-agent edit localization
pattern shown by the v9.3 `a795abb` STATUS.md phase-title edit) as
additional support.

### 4.2 CD-8 file list (AD-8 §Concrete contents)

See Part 2 AD-8 for the canonical file list. Two corrections vs. the
V10-PREDESIGN proposal:

1. **T4b reassigned** from `coder.md` to `architect.md` (T4b is an
   architect prompt, not a coder prompt).
2. **Placeholder files for `architect.md`, `grpc-schema.md`, and
   `repo-ops.md`.** Each is a valid per-agent file with zero variants
   (except `architect.md`, which has the `mid-phase` variant from T4b).
   Placeholders preserve the "one file per agent" invariant that the
   custom-agent workflow and migration both depend on. Each placeholder
   costs ~150 tokens; the uniformity removes branches in every consumer.

### 4.3 `PROMPT-AUTHORING.md` — directory guidance file (Step 11 note 1)

Named `PROMPT-AUTHORING.md` (not `README.md`) to be descriptive for the
PM chat scanning the directory and to distinguish it from a generic
human-orientation readme. Uppercase distinguishes it from the lowercase
per-agent files.

**Content.**
- The "How to use these templates" guidance currently at the top of
  `PROMPT-TEMPLATES.md` (lines 7–17).
- The per-agent exceptions table currently at lines 48–58.
- The self-check rule currently at lines 61–76.
- A one-line pointer to METHODOLOGY.md `## Prompt Authoring Principles`
  for full authoring guidance.

**Size.** ~80–120 lines. Direct-readable by the PM chat immediately before
generating any prompt — this replaces the equivalent region at the top of
the monolith but is not duplicated inside every per-agent file.

### 4.4 OQ-9 — Directory name and non-prompt content

**Decision.** `docs/pack/prompts/`. Do not split; do not rename. PM-chat
operational templates (T1, T8, T13, T14 → `pm-chat.md`) live in the same
directory as agent prompts.

**Rationale.** Every file in the directory contains prompt text — text
prepared to be sent to an LLM or pasted by a developer into an LLM
session. T1 is a developer-pasted prompt. T8/T13/T14 are self-prompts the
PM chat uses on itself. The distinction is *which consumer*, not *whether
it is a prompt*. The directory name is accurate.

**Alternatives rejected.**
- `docs/pack/templates/` — "templates" already denotes SETUP_TEMPLATE.md
  and AGENT_KICKOFF_TEMPLATE.md in `supporting-docs/`; reusing the term
  adds ambiguity.
- `docs/pack/agent-prompts/` — implies agent-only; `pm-chat.md`'s
  variants are PM-chat prompts, not agent prompts. Reintroduces OQ-9's
  original concern.
- Split: `docs/pack/prompts/` + `docs/pack/workflows/` — two directories
  for ten files; adds a migration branch; AD-9 `x-<name>.md` files would
  have to pick one.

### 4.5 OQ-11 — Per-agent file format

**Decision.**
- **Frontmatter.** YAML, required. Required keys: `agent`, `variants`.
  Reserved keys permitted but unused in v10: `description`,
  `deprecated-by`, `notes`. Unknown top-level keys rejected.
- **Body.** One H1 title; optional short preamble paragraph; one
  `## Variant: <slug>` H2 heading per variant; variant body is free-form
  markdown from the heading to the next H2 or EOF.
- **PM chat variant lookup.** Read the file, parse frontmatter, locate the
  line matching `^## Variant: <slug>\s*$`, copy the body through to the
  next H2 or EOF.
- **Machine-parseable** via standard YAML + regex. Enforceable by
  `validate-pack.py`.

**Frontmatter schema:**

```yaml
---
agent: coder
variants:
  - standard
  - fix-cycle
---
```

| Key | Required | Type | Meaning |
|---|---|---|---|
| `agent` | yes | string | Agent identifier matching pack roster (AD-10) or `x-<name>` custom. For `pm-chat.md`, value is `pm-chat` (reserved non-agent identifier; PM chat is the consumer, not an agent) |
| `variants` | yes | list of strings | Zero or more variant slugs matching `^[a-z][a-z0-9-]*$`. Each slug must appear as a `## Variant: <slug>` H2 below. Empty list legal for placeholder files |

**Body structure rules:**

1. Exactly one H1 at the top. Conventional text: `# <agent> — prompt
   templates` (or `# <agent> — PM chat templates` for `pm-chat.md`).
2. Optional one-paragraph preamble between H1 and the first H2.
3. One H2 per variant, literally `## Variant: <slug>`; deviation = format
   violation.
4. No H1 or H2 inside a variant body. H3 and below are permitted.
5. Variant body is free-form markdown carrying the prompt text that the
   PM chat copies and customizes.
6. No top-of-file preamble other than H1 + optional paragraph. The
   "Prompt Authoring Principles" content lives only in METHODOLOGY.md;
   the per-agent exceptions table and self-check rule live in
   `PROMPT-AUTHORING.md`.

### 4.6 Agent report file convention (Step 11 note 3, V10-PREDESIGN Part 12)

The prompt template format incorporates the agent report file convention
validated during the v10 design process. Every variant that produces a
deliverable includes a `REPORT FILE:` field and the following framing:

- **Read-only agent variants** (reviewer, planner, docs-researcher,
  tester read-only, auditor, pack-architect, pack-planner, pack-reviewer,
  pack-docs-researcher): `"This is a read-only session. Do not modify any
  existing files. The only file you may create is the designated report
  file below. Write it in markdown only."`
- **Write-capable agent variants** (coder, repo-ops, some tester): `"Write
  your deliverable to the designated report file below in markdown, in
  addition to any files you create or modify as part of your task."`
- **Report file field**: `REPORT FILE: <path>` — filled in per task by the
  PM chat.
- **Closing instruction**: `"Write your findings to the report file when
  complete."`
- **Chunking instruction**: `"If your report exceeds 300 lines, write it
  in sections — create the file with the first section, then read it back
  and append subsequent sections."`

These fields are embedded in the per-variant body of each agent file
where they apply. The PM chat's prompt-generation workflow fills in the
`REPORT FILE:` path per task; a project convention for report locations
(e.g., `docs/project/reports/`) is established during project kickoff.

**PM-CHAT.md behavioral rule.** When generating any agent prompt, the PM
chat always includes a REPORT FILE path and the framing appropriate to
the agent's permission mode. This rule is added as a `## Behavioral rules`
bullet in PM-CHAT.md (Part 5 §5.10).

### 4.7 OQ-4 — pm-startup behavior after reorg

**Decision.** pm-startup does **not** read any prompt file at startup.
The prompts directory is opaque to startup. The PM chat reads individual
`docs/pack/prompts/<agent>.md` files on demand at prompt-generation time.

pm-startup drops its existing RAG-freshness check on
`docs/pack/PROMPT-TEMPLATES.md` (the file no longer exists). The
METHODOLOGY.md freshness check is retained.

No manifest file. No directory scan at startup.

**Impact on `project-template/skills/pm-startup/SKILL.md`.** The Step 4
RAG-freshness check drops the PROMPT-TEMPLATES.md line; the surrounding
prose updates to name only METHODOLOGY.md.

**Impact on `project-template/docs/pack/PM-CHAT.md`.** File-access
strategy table gains a `docs/pack/prompts/<agent>.md` row (Direct read,
on-demand at generation time). The `PROMPT-TEMPLATES.md` row is removed;
the mcp-local-rag recommendation drops PROMPT-TEMPLATES.md and keeps
METHODOLOGY.md only.

**Alternatives rejected.**
- *Manifest file in the prompts directory.* Rejected — every new
  `x-<name>.md` would have to update the manifest; drift surface. Also no
  startup need.
- *Directory scan at startup reporting "N prompts available."* Rejected —
  display noise for information the user does not consume; would cross-
  tool assume shell `ls` (Claude Desktop + Project knowledge has no
  equivalent).

### 4.8 Stale-reference sweep for PROMPT-TEMPLATES.md (V9 Lesson 4)

Must-update in v10.0 (operational docs):
- `project-template/docs/pack/PM-CHAT.md` — file-access strategy table,
  mcp-local-rag recommendation.
- `project-template/skills/pm-startup/SKILL.md` — Step 4 RAG-freshness
  check.
- `project-template/CLAUDE.md` / `AGENTS.md` / `GEMINI.md` — Document
  locations table's `docs/pack/` row (trinity rule).
- `project-template/README.md` — any file-listing reference.
- `supporting-docs/METHODOLOGY.md` — references to PROMPT-TEMPLATES.md as
  the location of per-agent templates point to `docs/pack/prompts/`.
- `supporting-docs/PROMPT-TEMPLATES.md` — deleted at migration.
- `QUICKSTART.md` — rewritten as router under BD-044.
- `supporting-docs/CLI-PM-SETUP.md`, `SETUP_TEMPLATE.md`,
  `DEPENDENCIES.md` — any references updated.
- `.github/workflows/` / `scripts/validate-pack.py` — structural checks
  updated.

Annotate but do not mutate (historical records):
- `maintenance-docs/V9-DESIGN.md` — supersession notes next to references
  to PROMPT-TEMPLATES.md as a shipping artifact.
- `maintenance-docs/V9-AUDIT-REPORT.md` if present — same treatment.
- Pre-v9 guides and origins — no action.
- `CHANGELOG.md` entries — no action (historical).

Complete touch-point list consolidated in Part 8.

---

## Part 5 — Design: Custom Agent and Skill Support

Addresses V10-PREDESIGN CD-1, CD-2, CD-3, CD-4, CD-6, CD-7, CD-9 (all
confirmed in Part 2 ADs) and OQ-1, OQ-2, OQ-7, OQ-8. Specifies the
detection workflow, the Procedure 5 outline for METHODOLOGY.md, the
PLATFORM-SKILLS.md section specifications, PM-CHAT.md additions, trinity
routing-table additions, and validate-pack.py CI updates.

### 5.1 Creation workflow (AD-4 §Four approval gates)

Creation uses three paths (describe / one-tool seed / existing-file)
converging on four approval gates. Per custom-agent request the PM chat
produces:

| Artifact | Path | Source of truth for format |
|---|---|---|
| Claude agent file | `.claude/agents/x-<name>.md` | AD-2 row: Claude pack agents |
| Codex agent file | `.codex/agents/x-<name>.toml` | AD-2 row: Codex pack agents (both `name` and `description` required; Codex silently ignores agents missing either) |
| Gemini agent file | `.gemini/agents/x-<name>.md` | AD-2 row: Gemini pack agents |
| Custom prompt file | `docs/pack/prompts/x-<name>.md` | Part 4 §4.5 format |
| PLATFORM-SKILLS.md row | `## Custom agents` section | §5.2 below |
| Routing-table rows (trinity) | `### Custom agents` sub-section in CLAUDE.md / AGENTS.md / GEMINI.md | §5.6 |
| SKILL.md files × 3 (if custom skill) | `.claude/skills/x-<name>/`, `.codex/skills/x-<name>/`, `.gemini/skills/x-<name>/` | AD-2 row: skills |
| PLATFORM-SKILLS.md row (if custom skill) | `## Custom skills` section | §5.2 |

**Not created:** no `.codex/config.toml` edit (§5.4); no manifest file.

**Approval gates:**

| Gate | Artifact under review | Developer decision |
|---|---|---|
| G-design | Clarifying-question answers + draft agent description (purpose, scope, read-only/write, variants, custom-skill dependency, PLATFORM-SKILLS.md dimension) | Shape is right |
| G-files | Drafts of all three agent files + prompt file + optional SKILL.md set, side-by-side | Content is right |
| G-registration | PLATFORM-SKILLS.md row(s); trinity routing-table rows; skill load lists | Registration surfaces are right |
| G-commit | `git add` list; proposed commit message `feat: vN — add custom agent x-<name>` | Commit proceeds |

Aborting at any gate leaves the project in the pre-gate state (the pre-
G-commit state is in the working tree; `git restore` reverts cleanly).

Path-specific differences (all converge on the same four gates):

- **Path 1 describe-driven.** G-design asks clarifying questions §5.7
  Procedure 5.1 step 2; G-files generates all three forms from scratch.
- **Path 2 one-tool seed.** G-design reads the seed, drafts answers from
  it, asks follow-ups for fields the seed does not supply (e.g., seed is
  Claude `.md` — PM chat asks about Codex `sandbox_mode`, Gemini
  `temperature`/`max_turns`); G-files emits seed (normalized if needed)
  plus other two forms plus prompt.
- **Path 3 existing-file adoption.** G-design reviews file, lists
  deviations, asks for rewrite confirmation; G-files emits rewritten form
  in correct tool directory plus the other two tool forms plus prompt.

### 5.2 PLATFORM-SKILLS.md — Custom sections spec (CD-7 / AD-7)

Added to `project-template/docs/pack/PLATFORM-SKILLS.md` immediately after
the current `## Full skill inventory` section, in this order:
`## Custom agents` then `## Custom skills`.

**`## Custom agents` section (placeholder in pack template; populated per project by Procedure 5):**

```markdown
## Custom agents

Project-specific agents created via Procedure 5 (METHODOLOGY.md Part 7).
All entries in this section begin with `x-`. The PM chat treats these as
equivalent to pack agents for skill loading and routing, with the single
difference that they are project-owned and preserved across pack
upgrades.

| Agent | Purpose | Dimension | Phase routed to | Tier 1 skills | Tier 2 skills | Read/write mode |
|---|---|---|---|---|---|---|
| `x-deployer` | Release packaging and staging deploy | Component Roles | Repo operations | repo-ops | deployment-apple, deployment-python | write |

*This row is illustrative. The PM chat replaces it with real entries during
Procedure 5. If a project has no custom agents, the section body is
`*No custom agents defined for this project.*`.*
```

Column semantics: Agent stem (must match `^x-[a-z][a-z0-9-]*$`); Purpose
(one sentence); Dimension (which PLATFORM-SKILLS.md dimension this agent
extends — Platform Targets, Languages, Component Roles, or Communication
Protocols); Phase routed to (matches existing Phase routing column);
Tier 1 skills (comma list from Tier 1 inventory); Tier 2 skills (Tier 2
inventory + `x-` custom skills); Read/write mode (must match the agent
file's sandbox/tools configuration).

**`## Custom skills` section (same placement model):**

```markdown
## Custom skills

Project-specific skills created via Procedure 5 (METHODOLOGY.md Part 7).
All entries in this section begin with `x-`. Loaded by agents via the
same instruction block as pack skills — see "Step 3 — Generate the
prompt" above.

| Skill | Description | Dimension | Loaded by |
|---|---|---|---|
| `x-brokerage-api` | OT broker-adapter patterns, capability masks, idempotency | Communication Protocols | reviewer, auditor-code, x-deployer |

*This row is illustrative. The PM chat replaces it with real entries during
Procedure 5. If a project has no custom skills, the section body is
`*No custom skills defined for this project.*`.*
```

Column semantics: Skill stem; Description (one sentence); Dimension
(which PLATFORM-SKILLS.md dimension this skill extends — Platform Targets,
Languages, Component Roles, or Communication Protocols); Loaded by
(comma list of pack agents by stem or custom agents by `x-<name>`; must
match PM-CHAT.md pack roster or `## Custom agents` rows).

### 5.3 OQ-1 — Pack roster mechanism

**Decision.** Hardcoded `## Pack agent roster` section in
`project-template/docs/pack/PM-CHAT.md`, enforced by validate-pack.py
against `project-template/.claude/agents/` filenames. The roster is the
authoritative list of agent filename stems the PM chat treats as "known
pack agent; do not classify as custom."

Section content (positioned after `## Role`, before `## Before starting a
new project`):

```markdown
## Pack agent roster

The following are the canonical v10 pack agents. Any agent file whose
stem is NOT in this list and does NOT begin with `x-` is an
improperly-added agent (see "Detection of improperly added files" below).

- architect
- auditor
- auditor-architecture
- auditor-code
- auditor-docs
- auditor-ops
- auditor-security
- auditor-tests
- auditor-ui
- coder
- docs-researcher
- grpc-schema
- planner
- repo-ops
- reviewer
- tester
```

When a future pack version adds or removes a pack agent, PM-CHAT.md is
updated in the same commit. Drift between the roster and the actual
`.claude/agents/` directory is caught by validate-pack.py Check 7.

**Alternatives rejected.**
- *Derive roster from PLATFORM-SKILLS.md agent rows.* Rejected — that
  section is human prose with irregular spacing; a reliable parser is a
  new dependency, a brittle parser is a drift source.
- *New registry file `docs/pack/AGENT-ROSTER.md`.* Rejected — adds a
  third place to keep the agent list. Elegance preference: fewer files,
  fewer conventions.
- *Derive from the filesystem at runtime* (`ls .claude/agents/` minus
  `x-*`). Rejected — the runtime filesystem is what the roster is used to
  classify; circular. Also fails on Claude Desktop + Project knowledge,
  which has no `ls` equivalent.

### 5.4 OQ-2 — Codex config.toml (resolved per Step 2 C-1)

**Decision.** No per-agent `[agents.<name>]` registration entry exists in
documented Codex. Codex auto-discovers `.codex/agents/*.toml` files by
the `name =` field inside each file (Step 2 Fact 1).

The V10-PREDESIGN Part 4 touch-point row "`project-template/.codex/config.toml`
— Custom agent registration documentation" is **removed**. The
V10-PREDESIGN Part 5 workflow sub-step "PM chat adds `[agents.x_name]`
entry" is **removed**. The detection scan does not cross-check
`.codex/config.toml` against `.codex/agents/*.toml` presence.

The global `[agents]` settings table in `config.toml`
(`agents.max_threads`, `agents.max_depth`, `agents.job_max_runtime_seconds`)
is unaffected by v10 and unrelated to custom agents.

### 5.5 OQ-8 — `x-` prefix future collision policy

**Decision.** The `x-` filename namespace is **reserved for project
customizations**. The pack itself ships no agent, skill, or prompt file
whose name begins with `x-` in any of its template directories.
validate-pack.py Check 8 (§5.8 and Part 10 §10.1 V-CI-05) enforces.

Corollary for the hypothetical collisions named in OQ-8:

- *Project creates `x-deployer.md`; future pack adds `deployer.md`.* No
  filename collision. Both coexist; the PM chat's roster treats
  `x-deployer` as custom and `deployer` as pack.
- *Project creates `x-auditor-perf.md`; future pack adds
  `auditor-perf.md`.* No filename collision. Conceptual overlap (two
  auditor-perf things) is surfaced at migration time, where the developer
  decides whether to retire the custom or keep both.

Reservation removes the need for the detection scan to special-case a
file named `x-foo.md` that IS a pack file vs. one that is NOT. One rule,
one direction: `x-` means custom, always.

### 5.6 Trinity routing-table additions

Each trinity file (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`) receives a new
sub-section at the end of the Phase routing table:

```markdown
### Custom agents

Project-specific agents created via Procedure 5. See
`docs/pack/PLATFORM-SKILLS.md` § "Custom agents" for the canonical list
and full skill assignments. All custom agent names begin with `x-`.

| Phase | Agent | Key reason |
|---|---|---|
| (Developer / PM chat adds rows per project during Procedure 5) |  |  |
```

Procedure 5.1 adds a row to all three trinity files in the same commit
(trinity rule; the row content is identical in all three). Tool-specific
invocation syntax (Claude Task tool, Gemini `@agent-name`) is already
handled in each file's existing content below the Phase routing table;
no per-tool deviation is introduced by the sub-section.

### 5.7 Procedure 5 outline for METHODOLOGY.md

Added to METHODOLOGY.md Part 7 ("BACKLOG and TODO Management") immediately
after Procedure 4. Section header: **"Procedure 5 — Custom agent and
skill workflow."**

#### Procedure 5.1 — Creating a custom agent

Triggered when the developer asks for a custom agent.

1. **Pre-check (G-design).** Verify no existing files for the proposed
   name (`.claude/agents/x-<name>.md`, Codex, Gemini, prompt). If any
   exist, route to Procedure 5.3 (completing a partial registration).
2. **Clarifying questions.** Purpose; which PLATFORM-SKILLS.md dimension
   this agent extends (Platform Targets, Languages, Component Roles, or
   Communication Protocols); primary phase served; read-only or write;
   Bash/Web/MCP tool requirements; number of prompt variants; existing
   pack skills loaded vs. new custom skill; which pack agent the PM chat
   would have routed to absent this custom (for the routing-table row).
3. **Drafts (G-files).** PM chat drafts all four files (Claude, Codex,
   Gemini, prompt). Presents side-by-side; iterate until approved.
4. **Registration drafts (G-registration).** PLATFORM-SKILLS.md
   `## Custom agents` row; trinity Phase routing rows (TRIO); if custom
   skill, `## Custom skills` row plus three SKILL.md files.
5. **Commit (G-commit).** PM chat presents `git add` list and commit
   message; developer explicitly approves per CLAUDE.md pack rule. One
   commit, all artifacts.

#### Procedure 5.2 — Creating a custom skill (standalone)

Triggered when an existing pack or `x-` custom agent will load a new
project-specific skill and no custom agent creation is in flight.

1. Pre-check: no `x-<name>` skill directory exists in any of the three
   tool skills directories.
2. Clarifying questions: purpose; which PLATFORM-SKILLS.md dimension this
   skill extends (Platform Targets, Languages, Component Roles, or
   Communication Protocols); which agents load it; `allowed-tools`.
3. Drafts (G-files): three SKILL.md files with identical frontmatter and
   body across the three tool directories.
4. Registration drafts (G-registration): PLATFORM-SKILLS.md
   `## Custom skills` row naming which agents load the skill.
5. Commit (G-commit): per Procedure 5.1 step 5.

#### Procedure 5.3 — Completing a partial registration (Unregistered)

Triggered when the detection scan reports an Unregistered custom agent or
skill.

1. PM chat lists present files and missing artifacts per §5.9.
2. Developer approves reconstruction. PM chat drafts missing tool forms,
   prompt file, and/or PLATFORM-SKILLS row and routing-table entries.
3. G-registration approval.
4. G-commit approval.

#### Procedure 5.4 — Adopting an improperly-added file

Triggered when the detection scan reports an Improperly added file
(non-`x-`, not in pack roster).

1. PM chat confirms invisibility consequence (file is on disk but not in
   routing tables or skill-load lists).
2. Developer chooses:
   - **Adopt as custom.** Rename to `x-<name>`; route to Procedure 5.3.
   - **Remove.** PM chat produces `git rm` commands for approval (per
     CLAUDE.md destructive-op rule: explicit approval before execution).
   - **Defer.** File stays on disk, stays invisible; scan flags it at
     every subsequent trigger.

#### Procedure 5.5 — Detection scan as a phase-gate step

The phase-gate check in Procedure 1 gains sub-step 5a:

> **5a. Run custom-file detection scan (Procedure 5).** If any
> unregistered or improperly-added files are found, pause and route to
> the appropriate sub-procedure (5.3 or 5.4). Developer may Defer; do
> not block the phase on unregistered custom files if the developer
> explicitly chooses Defer, but do not include those files in the
> upcoming prompt generation either.

#### Procedure 5.6 — Reference tables

Procedure 5 ends with two reference tables (one for custom agents, one
for custom skills) enumerating registration artifacts, so a developer
can answer "is my custom agent properly registered?" from Procedure 5
alone.

### 5.8 Detection workflow (OQ-1, OQ-2, OQ-7, OQ-8 converge here)

#### Triggers

| Trigger | Scope | Rationale |
|---|---|---|
| PM chat startup (`/pm-startup` or equivalent) | Full scan of seven directories | Session start; PM chat context must reflect on-disk state |
| Phase-gate check (Procedure 1 step 5a) | Full scan | Catch manual additions made between sessions |
| Custom-agent creation workflow (Procedure 5.1 step 1) | Same-name pre-check only | Prevents accidental overwrite |

No tool-emitted file-edit hook is used. Step 2 Contradiction C-3: Codex
emits no file-edit hook; Step 2 Fact 2: Claude Code has live detection
but session-local, not a PM-chat-level signal. Tool-agnostic PM-chat-
level scanning is the only cross-tool-consistent mechanism.

#### Directories scanned (AD-10 §Detection directories)

1. `.claude/agents/*.md`
2. `.codex/agents/*.toml`
3. `.gemini/agents/*.md`
4. `.claude/skills/*/SKILL.md`
5. `.codex/skills/*/SKILL.md`
6. `.gemini/skills/*/SKILL.md`
7. `docs/pack/prompts/*.md`

No other directories are in detection scope.

#### Classification rules

| Observed | Classification | PM chat action |
|---|---|---|
| Stem in pack roster (agents, skills, or prompts-list) | **Pack** | OK — no action |
| Stem begins with `x-` AND all registration artifacts present (§5.9) | **Registered custom** | OK — no action |
| Stem begins with `x-` AND some registration artifact missing | **Unregistered custom** | Flag; offer Procedure 5.3 |
| Stem does NOT begin with `x-` AND NOT in pack roster (and NOT the prompt-dir exemption) | **Improperly added** | Flag; explain invisibility; offer Procedure 5.4 |

#### Exemption

The `pm-chat.md` prompt file is exempt from agent-roster comparison —
its frontmatter `agent: pm-chat` is a reserved non-agent identifier
(Part 4 §4.5). No other non-`x-` file is exempt.

#### What the PM chat says (phrasing for METHODOLOGY.md Procedure 5)

- **Unregistered custom.** "I found `x-<name>` files at `<paths>` but
  registration is incomplete: missing `<specifics>`. Do you want me to
  complete registration? (This will produce drafts of the missing
  artifacts for your review before committing.)"
- **Improperly added.** "I found `<path>` which is not a pack agent and
  does not begin with `x-`. This file is currently invisible to the PM
  chat's prompt generation and routing. Do you want me to adopt it as a
  custom agent? That would rename it to `x-<name>` and produce the
  missing companion files and registration entries."

### 5.9 Registration artifacts for a Registered custom agent

For `x-<name>` agent to be Registered, **all** of:

1. `.claude/agents/x-<name>.md` exists with valid YAML frontmatter
   (`name: x-<name>`).
2. `.codex/agents/x-<name>.toml` exists with valid TOML
   (`name = "x-<name>"` and non-empty `description`; both required).
3. `.gemini/agents/x-<name>.md` exists with valid YAML frontmatter.
4. `docs/pack/prompts/x-<name>.md` exists and passes Part 4 §4.5
   validation.
5. PLATFORM-SKILLS.md `## Custom agents` contains a row for `x-<name>`.
6. Each of CLAUDE.md / AGENTS.md / GEMINI.md `### Custom agents` sub-
   section contains a row for `x-<name>`.

For `x-<name>` custom skill to be Registered, **all** of:

1. `.claude/skills/x-<name>/SKILL.md` exists with valid frontmatter.
2. `.codex/skills/x-<name>/SKILL.md` exists with valid frontmatter.
3. `.gemini/skills/x-<name>/SKILL.md` exists with valid frontmatter.
4. PLATFORM-SKILLS.md `## Custom skills` contains a row for `x-<name>`.

Missing any artifact → Unregistered.

### 5.10 PM-CHAT.md additions (summary)

- **`## Pack agent roster` section.** §5.3. After `## Role`, before
  `## Before starting a new project`.
- **`## Custom agent and skill workflow` section.** After `## Behavioral
  rules`. One-paragraph overview pointing to METHODOLOGY.md Procedure 5;
  summarized detection-and-classification rule; reservation note.
- **File-access strategy additions.** `docs/pack/prompts/<agent>.md`
  direct-read row (Part 4 §4.7). Directory-listing row for the seven
  detection directories. Remove PROMPT-TEMPLATES.md row.
- **Behavioral rules additions.** Three new bullets:
  - *Custom files via Procedure 5 only.*
  - *Detection scan at every startup and every phase gate.*
  - *Pack roster is in `## Pack agent roster` above; do not infer it from
    any other file.*
- **Agent report file rule** (Part 4 §4.6, Step 11 note 3). When
  generating any agent prompt, always include a REPORT FILE path and the
  framing appropriate to the agent's permission mode.

PM-CHAT.md is a single tool-agnostic file; the trinity rule does not
apply to it.

### 5.11 validate-pack.py updates

Four new checks added to the pack CI:

- **Check 6 — prompts-directory format.** Part 4 §4.5.
- **Check 7 — pack-agent-roster consistency.** Parse PM-CHAT.md
  `## Pack agent roster`; compare to `.claude/agents/*.md` stems; fail on
  mismatch.
- **Check 8 — reserved `x-` prefix.** For each of the seven pack
  template scan locations, fail if any filename or directory begins with
  `x-`.
- **Check 9 — BD-044 structure.** Detailed in Part 7 §7.13.

These checks apply to the **pack repo only**; downstream projects with
`x-` files are correct.

### 5.12 Incremental testability and rollback

Custom agent and skill support is structurally additive. Any commit in
the creation workflow (G-commit) can be reverted with `git revert`
cleanly — the artifacts are the only changed files, and none of them are
required by pack invariants (the PLATFORM-SKILLS.md "no custom X
defined" placeholder line is the natural empty state).

Pre-commit aborts (before G-commit) leave unstaged working-tree edits
revertable with `git restore`. No half-committed states are possible.

### 5.13 Integration with other BDs

- **BD-045 (Part 3).** BD-045 edits trinity files in the LSP section
  and the anti-patterns list. Custom-agent support adds `### Custom
  agents` sub-section at the end of the Phase routing table. Different
  sections; no collision. Commit sequencing coordinates both.
- **BD-046 migration (Part 6).** Custom-file preservation is AD-5; the
  detection directories are shared; the pack-agent roster comes from
  PM-CHAT.md.
- **BD-044 init-project (Part 7).** init-project.sh never creates `x-`
  files. First post-init PM-chat session runs the detection scan against
  a clean project (only pack files present → all OK).

---

## Part 6 — Design: Migration v9.3 → v10.0

Addresses V10-PREDESIGN CD-5, CD-13 (Part 2 ADs), and OQ-3. Specifies the
migration script logic, the preservation mechanism, the PLATFORM-SKILLS
and trinity merge rules, the rollback plan, the incremental-testability
contract, and the `MIGRATION-v9-to-v10.md` outline.

### 6.1 Preservation mechanism (AD-5 detail)

In-place skip. The migration script replaces pack-owned files by removing
only the pack-roster set and copying the new pack template; it never runs
`rm -rf` on any directory that can contain `x-` files.

| Classification | Migration action |
|---|---|
| **Pack** (stem in v10 pack roster) | Replace with v10 pack version |
| **`x-` prefixed** (project customization) | **Preserve in place.** Do not touch, do not copy over, do not rename |
| **Anything else** (non-pack, non-`x-`) | **Preserve in place and flag.** Surface in migration report for post-migration Procedure 5.4 |

The v10 pack roster comes from three authoritative sources at migration
time:
- **Agents:** `docs/pack/PM-CHAT.md` `## Pack agent roster` (Part 5 §5.3).
- **Prompts:** Part 4 §4.2 file list (ten canonical files +
  `PROMPT-AUTHORING.md`).
- **Skills:** enumerated from `ls "$PACK/project-template/skills/"` at
  run time.

Per-directory replacement recipe (conceptual; concrete shell in §6.8):

```text
for tool in claude codex gemini:
    for pack_agent in $(ls $PACK/.../$tool/agents/):
        rm -f .${tool}/agents/$pack_agent
        cp $PACK/.../$pack_agent .${tool}/agents/$pack_agent
    for pack_skill in $(ls $PACK/project-template/skills/):
        rm -rf .${tool}/skills/$pack_skill
        cp -r $PACK/.../$pack_skill .${tool}/skills/$pack_skill

mkdir -p docs/pack/prompts
cp $PACK/.../docs/pack/prompts/*.md docs/pack/prompts/
# (docs/pack/prompts/ did not exist in v9.3; created fresh)
```

**Why in-place skip, not temp-move-and-restore.**
- Interrupted migration leaves custom files in temp directory under
  temp-move-and-restore; in-place skip never moves them.
- Move-then-restore has two write sides; a buggy restore path lands files
  in the wrong place. Selective-replace has one write side.
- `git status` after the script shows precisely which pack files changed
  and which custom files did not — audit trail is clean.

**Failure modes explicitly surfaced:**

| Condition | Behavior |
|---|---|
| `x-` file malformed (invalid frontmatter) | Preserved as-is; noted in report; PM chat Procedure 5.3 handles post-migration |
| Pack-named file hand-edited by developer | Replaced by v10 version; `git diff` shows the overwrite pre-commit; rollback available (§6.6) |
| Stray `x-` file inside pack skill directory (e.g., `.claude/skills/planning/x-extra.md`) | Migration **stops** at pre-flight (§6.3); developer must move the file to a proper `x-<name>/SKILL.md` first |
| `.codex/config.toml` has hand-written `[agents.<name>]` entries (speculative v10-predesign assumption) | Left in place (no-ops per §5.4); noted in report |
| `PROMPT-TEMPLATES.md` customized | Backup and split per §6.4 |

### 6.2 Baseline — v9.3 only (AD-13 detail)

Pre-flight invariants (§6.3) confirm the project's v9.3 state before any
write. Required:

1. `docs/pack/PROMPT-TEMPLATES.md` exists (if missing, project is pre-v9.2
   or partially migrated; not supported).
2. `.claude/agents/` contains at least the 16 v9.3 pack agents.
3. `.gemini/agents/` exists and contains `.md` files (v9.3 BD-043 native
   subagents).
4. PLATFORM-SKILLS.md path is `docs/pack/PLATFORM-SKILLS.md` (v9.2+
   BD-042 relocation).

If any invariant fails, the script prints a diagnostic and refuses to
proceed. The script does **not** normalize a v9.0/v9.1/v9.2 project to
v9.3 first — out of scope per AD-13.

### 6.3 Pre-flight checks (S0)

In order, stopping at first failure:

1. Clean working tree (`git status --porcelain` empty). Offer to `git
   stash`.
2. On branch `migration-v9-to-v10` (create if not).
3. Pack repo path `$PACK` exists; `git -C "$PACK" rev-parse v9.3`
   succeeds; v10 tag or v10-dev branch exists for pack content.
4. Baseline invariants from §6.2.
5. `x-` file audit (record paths and classifications).
6. Unclassifiable file audit (record non-pack non-`x-` files).
7. Stray `x-` files inside pack skill directories (stop with guidance).
8. Create `.pack-migration-backup/v9.3-to-v10.0/`; append
   `.pack-migration-backup/` to `.gitignore` if absent.

On success, write sentinel `stage-S0.done`.

### 6.4 OQ-3 — Prompt template migration for customized projects

**Decision.** Two linked passes:

1. **Diff against v9.3 baseline.** Source of truth:
   `$PACK/supporting-docs/PROMPT-TEMPLATES.md` at git tag `v9.3` (via
   `git -C "$PACK" show v9.3:supporting-docs/PROMPT-TEMPLATES.md`).
   Comparison is byte-exact after whitespace normalization (trailing
   spaces stripped, CRLF → LF).
2. **Mechanical split.** For both identical and divergent cases, the
   migration writes the v10 pack's fresh ten per-agent files and
   `PROMPT-AUTHORING.md` from `$PACK/project-template/docs/pack/prompts/`.
   Implementation note: the migration does **not** re-derive the split
   from the project's monolith. The v10 pack's per-agent files were
   produced by the pack maintainer as the canonical split of the v9.3
   baseline; every project gets identical content.
3. **If identical:** delete `docs/pack/PROMPT-TEMPLATES.md` from the
   project (after backup, §6.6). Migration report records
   `customization: none`.
4. **If diverged:** preserve the full original as
   `docs/pack/prompts/_v9-backup.md` (reserved filename). Set the
   `customization: divergence detected; reconciliation flag set` marker
   in the report. Post-migration, the PM chat invokes Procedure 5-R
   (§6.5) at first startup.

**v9.x incremental additions.** The v9.3 baseline already includes every
post-v9.0 addition (from `git log v9.0..v9.3 -- supporting-docs/PROMPT-TEMPLATES.md`):

| Commit | Version | Change | v10 destination |
|---|---|---|---|
| `f8758f9` | v9.1 | BD-038 Template 1 active-skills-list instruction | `pm-chat.md ## Variant: kickoff` |
| `a795abb` | v9.3 | Template 8 STATUS.md phase-title linking rule | `pm-chat.md ## Variant: backlog-status-update` |
| `8364b20` | v9.3 | BD-043 Gemini architecture references | distributed through split |

All three are present in the v10 pack's per-agent files by construction
because those files were derived from v9.3. No special handling needed
when the diff reports "identical."

**Why not auto-merge customizations.** Auto-merge would require parsing
the project's possibly-edited monolith against the v9.3 baseline, mapping
each changed section to a per-agent file, inserting at the right heading
level, and revalidating. All four steps are failure modes. The backup-
and-reconcile path delegates judgment to the developer (via PM chat) at a
time when PM chat is running against v10 and can present the decision
interactively. Matches V9 Lesson 1.

### 6.5 Procedure 5-R — Reconciliation (new sub-procedure in METHODOLOGY.md)

Triggered by presence of `docs/pack/prompts/_v9-backup.md` at PM chat
startup.

1. PM chat reads `_v9-backup.md` and the v10 pack prompt files.
2. PM chat computes a conceptual diff: v9.3 baseline content (which
   matches what is now in v10 per-agent files modulo reformatting) vs.
   `_v9-backup.md`. The meaningful diff is the project's customization.
3. PM chat surfaces each customization with proposed placement ("your
   project added X to Template 4; in v10 this would live in `coder.md
   ## Variant: fix-cycle` between these lines. Approve?").
4. Developer approves, modifies, or rejects each surfaced item.
5. PM chat writes approved changes to the relevant per-agent file(s).
6. PM chat offers to remove `_v9-backup.md`; commit message records the
   reconciliation. Once removed, Procedure 5-R does not run again.

Procedure 5-R is added to METHODOLOGY.md Part 7 alongside Procedure 5.

### 6.6 PLATFORM-SKILLS.md and trinity merge rules

PLATFORM-SKILLS.md and the three trinity files contain pack-owned regions
(most of the file) and project-owned regions (the `## Custom agents` /
`## Custom skills` sections in PLATFORM-SKILLS.md; the `### Custom
agents` sub-section plus the `**Active skills:**` line in each trinity
file). Migration preserves project-owned regions by positional splice.

#### PLATFORM-SKILLS.md rule

Project-owned region begins at the first occurrence of `## Custom agents`
or `## Custom skills`, whichever comes first. Everything from that line
to EOF is project-owned. Everything above is pack-owned.

Merge: pack region (from v10 pack template, up to first custom heading) +
project region (from v9.3 project file, from first custom heading to
EOF). On v9.3 projects (no custom sections exist yet), the v10 pack
template is used verbatim.

Why a positional rule rather than comment markers: the section headings
are themselves functional markers (Part 5 §5.2); a comment marker would
be a second source of truth that can drift.

#### Trinity file rule

Two splices per trinity file:

1. **`### Custom agents` sub-section.** Project-owned region is from the
   first `### Custom agents` line to the next H2 (`## Agent behavior` in
   the v10 template). On v9.3 (sub-section absent), v10 pack template is
   used.
2. **Active skills line.** The `**Active skills:**` prefix line in the
   Skill loading section. If the project's line contains real content
   (not the pack placeholder text), preserve it. Otherwise, use the v10
   pack placeholder.

Trinity rule: the same splice logic runs on all three trinity files
atomically within stage S5 (§6.8). Either all three are updated or none.

### 6.7 Rollback plan

Every destructive operation writes a backup to
`.pack-migration-backup/v9.3-to-v10.0/` before the write. The backup
contains:

- `manifest.txt` — one line per backed-up path (source, backup path).
- Full copies of `PROMPT-TEMPLATES.md`, `PM-CHAT.md`, `PLATFORM-SKILLS.md`,
  three trinity files, `METHODOLOGY.md`, `.codex/config.toml`,
  `.claude/settings.json`, `.mcp.json.example`.
- Full snapshots of `.claude/agents/`, `.codex/agents/`, `.gemini/agents/`,
  and all three skill directories (pre-migration).
- Full snapshot of `scripts/` and `agent-run.sh`.
- `stage-S<N>.done` sentinel files (for resumability).
- `report.md` summarizing all actions.

`x-` files are **not** backed up — they are never touched; a full rollback
leaves them in place.

**Rollback procedure (documented in MIGRATION-v9-to-v10.md):**

```bash
# 1. Uncommit if already committed
git log --oneline -5
git revert <hash>     # or: git reset --hard <parent> before push

# 2. Restore from backup
BACKUP=".pack-migration-backup/v9.3-to-v10.0"
cp "$BACKUP/docs/pack/PROMPT-TEMPLATES.md" docs/pack/PROMPT-TEMPLATES.md
cp "$BACKUP/docs/pack/PM-CHAT.md" docs/pack/PM-CHAT.md
cp "$BACKUP/docs/pack/PLATFORM-SKILLS.md" docs/pack/PLATFORM-SKILLS.md
cp "$BACKUP/CLAUDE.md" CLAUDE.md
cp "$BACKUP/AGENTS.md" AGENTS.md
cp "$BACKUP/GEMINI.md" GEMINI.md
cp "$BACKUP/.codex/config.toml" .codex/config.toml
cp "$BACKUP/.claude/settings.json" .claude/settings.json
rm -rf .claude/agents .codex/agents .gemini/agents
cp -r "$BACKUP/.claude/agents" .claude/agents
cp -r "$BACKUP/.codex/agents"  .codex/agents
cp -r "$BACKUP/.gemini/agents" .gemini/agents
rm -rf .claude/skills .codex/skills .gemini/skills
cp -r "$BACKUP/.claude/skills" .claude/skills
cp -r "$BACKUP/.codex/skills"  .codex/skills
cp -r "$BACKUP/.gemini/skills" .gemini/skills
rm -rf scripts
cp -r "$BACKUP/scripts" scripts
cp "$BACKUP/agent-run.sh" agent-run.sh
chmod +x agent-run.sh scripts/*.sh

# 3. Remove new v10 directory
rm -rf docs/pack/prompts

# 4. Remove backup directory (optional)
rm -rf .pack-migration-backup

# 5. Verify
ls .claude/agents/ | wc -l    # expect 16
```

**Rollback guarantees.**
- No data loss on pack-owned files (every replaced file backed up;
  manifest records all).
- No data loss on `x-` files (never touched, forward or back).
- No data loss on project-owned docs (BACKLOG.md, STATUS.md, ARCHITECTURE.md,
  IMPLEMENTATION_PLAN.md, CHANGELOG.md, PACK-FEEDBACK.md are not touched
  by migration).
- Deterministic recovery — the rollback commands are a fixed sequence.

**Maintainer note for MIGRATION-v9-to-v10.md (V9 Lesson 4).** If a v10.x
patch reverses a v10.0 design decision that this guide prescribes, update
the guide in the same patch.

### 6.8 Migration stages (incremental testability contract)

The migration is one logical operation decomposing into eight stages (S0–S7).
Each stage writes sentinel `.pack-migration-backup/v9.3-to-v10.0/stage-S<N>.done`
on completion; a resumed migration reads sentinels and skips completed
stages. Each stage leaves the project in a valid state with post-stage
assertions.

| Stage | Action | Post-stage state | Assertion |
|---|---|---|---|
| **S0** | Pre-flight (§6.3) | Backup dir created; project unchanged | `git status` shows only `.pack-migration-backup/` untracked |
| **S1** | Selective-replace agent files (three tools); `x-` files untouched | Agents v10; skills and prompts still v9.3 | `./agent-run.sh --help`; each pack-agent invocation on trivial task succeeds |
| **S2** | Selective-replace skill directories; `x-` dirs untouched | Skills v10 | Skills visible to each tool |
| **S3** | Replace `scripts/`, `agent-run.sh`, `.codex/config.toml`, `.claude/settings.json`, `.mcp.json.example` | Config aligned with v10 | `./scripts/bootstrap.sh` runs; `./scripts/validate.sh` runs |
| **S4** | Create `docs/pack/prompts/` and copy ten canonical files + `PROMPT-AUTHORING.md` | Prompts directory alongside monolith | validate-pack.py prompts-dir check passes on new files |
| **S5** | Trinity + docs/pack splice merge (§6.6) for `CLAUDE.md` / `AGENTS.md` / `GEMINI.md`, `PLATFORM-SKILLS.md`, `PM-CHAT.md`, `METHODOLOGY.md` | Trinity + pack docs updated, custom regions preserved | Trinity-rule CI check passes; `git diff` shows only pack-owned region changes |
| **S6** | Diff `PROMPT-TEMPLATES.md` vs. v9.3 tag; identical → delete; diverged → backup as `_v9-backup.md` then delete | Monolith gone or backed up | Migration report shows split mapping |
| **S7** | Post-migration report written to `.pack-migration-backup/v9.3-to-v10.0/report.md` | Migration complete | Report lists: files replaced, `x-` files preserved, improperly-added files, prompt customization status, rollback command block, next-step PM chat prompt |

**Script boundary.** `migrate-v9-to-v10.sh` does **not** commit, does not
run tests, does not register custom agents (Procedure 5.3 handles that
at first pm-startup), does not reconcile `PROMPT-TEMPLATES.md`
customizations (Procedure 5-R handles that), does not touch project-owned
state docs.

### 6.9 MIGRATION-v9-to-v10.md outline

Structure matches `supporting-docs/MIGRATION-v8-to-v9.md`: self-contained,
procedural, automatable option at the end.

| § | Section |
|---|---|
| 1 | Title + automatable-option banner |
| 2 | What changed in v10 (three BD-item summaries + three structural shifts) |
| 2a | What does NOT change from v9.3 (pointer to Part 1 §v9.x compatibility — agent roles, skills, tool interchangeability, PACK-FEEDBACK, Desktop/CLI options all preserved) |
| 3 | Before you start (v9.3 baseline, working tree clean, pack v10 available, migration branch) |
| 4 | Step 1 — Run the migration script |
| 5 | Step 2 — Review the migration report |
| 6 | Step 3 — Verify (`bootstrap.sh`, `validate.sh`, agent count invariants, prompts directory validation) |
| 7 | Step 4 — First PM chat run (observe detection scan; reconcile `_v9-backup.md` if present) |
| 8 | Step 5 — Custom file registration (Procedure 5.3 / 5.4 if flagged) |
| 9 | Step 6 — Xcode companion files (per-machine, Apple projects) |
| 10 | Step 7 — Commit |
| 11 | What to do after migration (PM chat brief about v10 changes) |
| 12 | Rollback (§6.7) |
| 13 | Project-type-specific notes |
| 14 | Troubleshooting |
| 15 | Automated migration via AI CLI (paste-ready prompt pattern) |

**Automatable-option paste-ready prompt (draft):**

```text
You are performing a v9.3 → v10.0 migration of this project using the
AI Agent Config Pack. Set:

PACK="/path/to/pack"

Before starting: verify working tree is clean (git status). If not
clean, stop.

Instructions:

1. Read $PACK/supporting-docs/MIGRATION-v9-to-v10.md in full before
   doing anything.
2. Create branch: git checkout -b migration-v9-to-v10
3. Run $PACK/scripts/migrate-v9-to-v10.sh and report each stage's
   completion to me. Pause for my review and approval after each stage.
4. When the script completes, present the migration report and the git
   diff summary. Do NOT commit.
5. Run ./scripts/bootstrap.sh and ./scripts/validate.sh and report
   results.
6. Present the "What to do after migration" section so I know what to do
   with my first PM chat session (including any reconciliation flag set
   by the script).

Rules:
- Do NOT commit anything without my explicit review and approval.
- Do NOT modify any file starting with `x-` under any circumstance.
- Do NOT modify any file in the pack repo — only this project.
- If the script pauses or errors, report the stage and sentinel file
  state and wait for my direction. Do not attempt to recover by
  reversing individual file edits.
- If the Procedure 5-R reconciliation flag is set, do not attempt the
  reconciliation — PM chat handles that at first pm-startup after the
  migration commits.
```

Works on all three CLI tools (Claude Code, Codex, Gemini). On Claude
Desktop + filesystem MCP, the Desktop app can drive the script via the
same prompt with the MCP filesystem server enabled.

### 6.10 File locations

- Guide: `supporting-docs/MIGRATION-v9-to-v10.md`.
- Script: `scripts/migrate-v9-to-v10.sh` (pack repo, not a project file).
- Merge helpers: `scripts/merge-platform-skills.py`,
  `scripts/merge-trinity.py` (pack repo).
- Shared detection library: `scripts/lib/detect.sh` (Part 7 §7.2).

### 6.11 Integration with other BDs

- **BD-044 (Part 7).** §6.3 pre-flight checks 1, 3, 5, 6 are candidates
  for the shared library at `scripts/lib/detect.sh`. Migration-only
  checks (baseline invariants, §6.2) stay in the migration script.
- **BD-045 (Part 3).** BD-045 content lives in the pack-owned region of
  trinity files; the splice rule preserves custom content around it.
- **Part 5 custom-agent mechanism.** Preservation marker is `x-`; pack
  roster comes from PM-CHAT.md; seven scan directories are shared.

---

## Part 7 — Design: Project Initialization (BD-044)

Addresses V10-PREDESIGN CD-10 (AD-10) and OQ-5 and OQ-12. Specifies
`init-project.sh` design, the `scripts/lib/detect.sh` shared library, the
five-class project detection heuristic, the preview-and-confirm flow, the
new-project and existing-project paths, inline verification at every
stage, the QUICKSTART.md three-path router, the SETUP-NEW.md and
SETUP-EXISTING.md outlines, and the migration-guide naming convention.

### 7.1 OQ-5 — Two scripts with a shared detection library

**Decision.**

- **Two scripts** (not one with mode flags):
  - `scripts/init-project.sh` — creates a project installation (new or
    existing).
  - `scripts/migrate-v9-to-v10.sh` — upgrades a v9.3 pack install to v10.0
    (Part 6).
- **One shared library:** `scripts/lib/detect.sh`, sourced by both.
- Both live in the pack repo's top-level `scripts/` — never copied into
  projects.

**Rationale.** Divergent write logic (init does additive copy + skip;
migrate does replace-pack + preserve-`x-`), divergent pre-flight
invariants (init: no existing AI config; migrate: v9.3 baseline present),
and different failure blast radii make separate scripts cleaner than
conditional branches. Shared detection code is precisely the common
substrate.

**Alternatives rejected.**
- One script with `--init` / `--migrate` flags — long conditional
  branches inside every stage; bug in one mode surfaces in the other.
- Two scripts, no shared library — duplicate detection functions;
  V9 Lesson 1 drift risk.
- Shared Python module — both scripts are shell per pack convention; a
  Python detection dependency would add an interpreter requirement for
  pre-flight, contrary to the pack's zero-dependency stance. The two
  Python merge helpers (`merge-platform-skills.py`, `merge-trinity.py`)
  are justified only because structured markdown splicing is hard in
  shell; detection is not.

### 7.2 Shared library: `scripts/lib/detect.sh`

Sourced (not executed). Functions are small, named by what they detect,
and print `key: value` structured output. Every function is read-only
with respect to the target project.

```bash
# scripts/lib/detect.sh — shared detection helpers

detect_clean_working_tree()     # working-tree: clean|dirty
detect_git_repo()               # git-repo: yes|no
detect_pack_path()              # pack-path: valid|missing|not-a-repo
detect_pack_version()           # pack-version: v<N.M> (tag or branch)
detect_ai_config()              # ai-config-markers: <comma list>
detect_x_files()                # x-files: <path>/line (scans 7 dirs)
detect_improperly_added_files() # improperly-added: <path>/line
```

init-project-only helpers remain in `init-project.sh`:

- `detect_language_markers()` — Swift, Python, Kotlin, TypeScript, Proto.
- `detect_source_files()` — source-extension counts at depth ≤ 2.
- `classify_project_state()` — applies the §7.3 rules.
- `compute_skip_list()` — which pack files to skip copying.
- `compute_gitignore_merge()` — appended `.gitignore` entries with dedup.
- `generate_pm_chat_prompt()` — end-of-run kickoff prompt.

Migration-only helpers stay in `migrate-v9-to-v10.sh` (baseline
invariant checks, PROMPT-TEMPLATES.md diff, `x-` preservation logic,
stage sentinels).

**Pack-repo layout:**

```
scripts/
├── init-project.sh             (NEW — BD-044)
├── migrate-v9-to-v10.sh        (NEW — BD-046)
├── merge-platform-skills.py    (NEW — BD-046)
├── merge-trinity.py            (NEW — BD-046)
├── validate-pack.py            (existing)
└── lib/
    └── detect.sh               (NEW — shared detection)
```

README.md Repository Layout section adds the `scripts/lib/` entry.

### 7.3 OQ-12 — Detection heuristics

**Decision.** Five project classes, deterministic from directory
contents. Same contents → same class, always.

| State | Meaning | Path |
|---|---|---|
| `new-empty` | Git repo, no source, no README (or only `.gitignore` / `LICENSE`), no AI config | New-project path (§7.5) |
| `new-bare` | Git repo, only `README.md` + optionally `.gitignore` / `LICENSE`, no source, no AI config | New-project path |
| `existing-bare` | Git repo with docs (`README.md`, `docs/`) but no source and no language markers and no AI config | Existing-project path (§7.6) |
| `existing-source` | Git repo with source files or language markers, no AI config | Existing-project path |
| `already-configured` | Any AI config marker present | **STOP** — §7.4 stop procedure |

**Source-files present — concrete rules.** Two evidence categories:

*Strong evidence* — language markers at depth ≤ 2:

| Language | Markers |
|---|---|
| Swift | `Package.swift`, `*.xcodeproj`, `*.xcworkspace` |
| Python | `pyproject.toml` |
| Kotlin | `build.gradle.kts`, `settings.gradle.kts`, `build.gradle` |
| TypeScript/Node | `package.json`, `tsconfig.json` |
| Proto | `proto/` with ≥1 `.proto` file |

*Weak evidence* — source-extension files at depth ≤ 2, threshold ≥ 3:

| Language | Extensions | Threshold |
|---|---|---|
| Swift | `*.swift` | ≥ 3 |
| Python | `*.py` | ≥ 3 |
| Kotlin | `*.kt`, `*.kts` | ≥ 3 |
| TypeScript | `*.ts`, `*.tsx` | ≥ 3 |

**Recursion depth cap: 2.** Monorepo subdirectories with their own
language markers are detected at depth 2. Deeper scan adds no signal and
is slow on real projects.

**README-only / near-empty:**

| Directory contents | Class |
|---|---|
| Empty (no git) | Refuse; ask developer to `git init` first |
| `.git/` only | `new-empty` |
| `.git/` + `.gitignore` and/or `LICENSE` | `new-empty` |
| `.git/` + `README.md` (+ optional `.gitignore`/`LICENSE`) | `new-bare` |
| `.git/` + `README.md` + `docs/` (markdown only, no source) | `existing-bare` |
| `.git/` + any source / language marker | `existing-source` |

**Monorepo detection.** Two or more distinct language markers →
`existing-source` with every detected language reported. Stage S9
(conditional removal) keeps conditional files for every detected
language; the unified template is additive.

**Platform-marker precedence.** None — the pack is additive. Both
`Package.swift` and `pyproject.toml` present means both are kept.

### 7.4 AI config stop condition

If `detect_ai_config` returns any of these at the target root, the script
stops:

| Marker | Meaning |
|---|---|
| `.claude/` | Claude Code config |
| `.codex/` | Codex config |
| `.gemini/` | Gemini CLI config |
| `CLAUDE.md` | Claude context file |
| `AGENTS.md` | Codex context file |
| `GEMINI.md` | Gemini context file |

Stop procedure:

1. Print a report naming found markers.
2. Prompt: "(a) already using this pack — run
   `scripts/migrate-v9-to-v10.sh` instead (see
   `supporting-docs/MIGRATION-v9-to-v10.md`); (b) using other AI tooling
   — remove or archive those files before running init-project.sh."
3. Exit 20.

init-project.sh does not merge existing AI config. Merge is the migration
script's job for pack upgrades; for other tooling, the developer decides
before running init.

### 7.5 Preview-and-confirm flow

**Contract.**

1. Detection is read-only. The only output before confirmation is the
   report on stdout.
2. After detection, the script prompts `Proceed? [y/N]`. Default is
   **No**. Only `y` / `Y` / `yes` proceeds.
3. Every operation in the report will be executed. Inline verification
   at each stage catches any deviation.
4. SIGINT, EOF, non-terminal stdin with non-`y` answer all exit 0 with
   no files changed. Scripts can pipe `yes` to auto-confirm for CI dry
   runs; the default is always confirm-required.

**Report format** (condensed; complete example in Step 7 §3.2):

```
init-project.sh detection report
=================================
Target project:  <path>
Pack:            <path>  (tag: v10.0)

Classification:  existing-source | existing-bare | new-bare | new-empty
Git repo:        yes
Working tree:    clean | dirty

Language markers found (depth ≤ 2):
  Swift:    Package.swift, MyApp.xcodeproj
  Python:   (none)
  ...

Source files present (depth ≤ 2):
  *.swift: 47

Existing AI config: none detected (proceeding) | <markers> (STOP)

Pack skill coverage:
  Swift:   FULL
  Kotlin:  NO COVERAGE    <-- gap reported

Existing docs at depth ≤ 1:
  README.md, docs/ARCHITECTURE.md

Planned operations
------------------
  [ADD — new files and directories]
    .claude/agents/     (16 agent files)
    ...
  [MERGE — appended and deduplicated]
    .gitignore          (N new lines, M duplicates)
  [CONDITIONAL REMOVE — files shipped by pack that don't apply here]
    pyproject.toml      (no Python detected — not copied)
    ...
  [SKIP — existing files preserved as-is]
    README.md, LICENSE, Package.swift, ...
  [END-OF-RUN OUTPUT]
    A PM chat kickoff prompt will be printed to stdout.

Developer transition notice
---------------------------
After this run, your project will use the pack's file names and
locations as the standard going forward:
  - Agent config: .claude/, .codex/, .gemini/
  - Context: CLAUDE.md, AGENTS.md, GEMINI.md at the project root
  - Methodology & templates: docs/pack/
  - Scripts: scripts/
  - Agent launcher: agent-run.sh at the project root

Your existing README.md, LICENSE, language manifest, and project docs
are unchanged and will continue to be authoritative.

Proceed? [y/N]
```

### 7.6 Paths — new-project and existing-project

Both paths share the same 11 stages (S0–S10). Behavioral differences at
S7, S8, S9, S10.

| Stage | Operation |
|---|---|
| **S0** | Detection + preview (§7.5). Read-only |
| **S1** | Create directory skeleton (`.claude/agents/`, `.codex/agents/`, `.gemini/agents/`, `docs/pack/`, `docs/project/`, `docs/reference/`, `scripts/`) |
| **S2** | Copy pack agent files (three tools) |
| **S3** | Copy `.codex/config.toml`, `.claude/settings.json`, `.mcp.json.example` |
| **S4** | Distribute skills — for each `$PACK/project-template/skills/<name>/`, copy `SKILL.md` to `.claude/skills/<name>/SKILL.md`, `.codex/skills/<name>/SKILL.md`, `.gemini/skills/<name>/SKILL.md` |
| **S5** | Copy `scripts/` and `agent-run.sh`; apply `chmod +x` |
| **S6** | Copy `docs/pack/` content: `METHODOLOGY.md`, `PM-CHAT.md`, `PLATFORM-SKILLS.md`, `PACK-FEEDBACK.md`, `prompts/` (entire directory per Part 4 §4.2 — 10 files + `PROMPT-AUTHORING.md`) |
| **S7** | Copy `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` from pack template. (Existing-project path never reaches here if AI config present — stop fires at S0) |
| **S8** | `.gitignore` merge — append pack lines, dedupe, preserve project order. Pack additions go under header comment `# --- AI Agent Config Pack additions (v10.0) ---` |
| **S9** | Conditional removal — per detected language, remove pack files that don't apply (Swift-only removes `pyproject.toml`, `pyrightconfig.json`, `server/`; etc.). For `new-empty` / `new-bare`, nothing detected → copy everything (v9 baseline behavior) |
| **S10** | Generate and print end-of-run PM chat kickoff prompt (§7.8) |

**File-list source of truth.** Stages S1–S7 derive their file lists from
`$PACK/project-template/` at run time, not from hardcoded lists. A new
v10.x pack agent is picked up automatically. Verification (§7.7) asserts
copied counts match pack counts.

**Skip list (existing-project only).** Files init-project.sh **never**
overwrites:
- `README.md`, `LICENSE*`.
- Language manifests: `Package.swift`, `*.xcodeproj`, `*.xcworkspace`,
  `pyproject.toml`, `poetry.lock`, `uv.lock`, `requirements*.txt`,
  `build.gradle*`, `settings.gradle*`, `package.json`, `tsconfig.json`,
  `package-lock.json`, `yarn.lock`.
- `.git/` internals (except `.gitignore`, which is merged).
- Any file inside `docs/` that already exists by filename.
- Any file inside `scripts/` that already exists by filename.

If a pack script name collides with an existing project script
(e.g., project has its own `bootstrap.sh`), the pack script is skipped
and the collision is reported under `[SKIP — existing project scripts]`
with a rename-and-retry recommendation.

**`.gitignore` merge.** Read project's existing; read pack template; for
each pack line, append if not already present (literal match after
trim). Pack additions go at the bottom under `# --- AI Agent Config
Pack additions (v10.0) ---`. Preserve project's existing ordering
(ignore patterns can be order-sensitive).

**Conditional removal table** (Stage S9):

| Pack file | Kept when | Removed when |
|---|---|---|
| `pyproject.toml`, `pyrightconfig.json`, `server/` | Python detected | Python not detected |
| Python scripts (`bootstrap-python.sh`, `format-python.sh`, `validate-python.sh`, `test-python.sh`) | Python detected | Python not detected |
| Swift scripts (`bootstrap-swift.sh`, `format-swift.sh`, `validate-swift.sh`, `test-swift.sh`) | Swift detected | Swift not detected |
| `proto/`, `proto-gen.sh`, `validate-proto.sh` | Proto detected | Proto not detected |

For `new-empty` / `new-bare` (nothing detected): **copy everything**;
the developer can remove unused conditional files by hand or re-run
init-project.sh after adding source files to trigger language-aware
pruning.

### 7.7 Inline verification at every stage

Each stage verifies its own work before the next stage begins. Scope is
**wider than the immediate change set** — after writing files, the
script greps for cross-references elsewhere to catch stale or missing
references a naive "did the cp succeed" check would miss.

**Per-stage local verification** (abbreviated; full table in Step 7 §6.2):

| Stage | Checks |
|---|---|
| S0 | Confirmation explicit `y/Y/yes`; `$PACK` valid; target is git repo; AI config still empty |
| S1 | All expected directories exist; no unexpected dirs |
| S2 | Claude/Codex/Gemini agent counts equal pack counts; trinity stem parity across three dirs |
| S3 | `.codex/config.toml` contains `[profile` header; `.claude/settings.json` non-empty |
| S4 | For each pack skill, SKILL.md present in three tool dirs; Claude body byte-identical to pack |
| S5 | All post-conditional-removal scripts present with `-x`; `agent-run.sh` executable |
| S6 | 10 prompt files + `PROMPT-AUTHORING.md` + 4 other pack docs present; each prompt passes Part 4 §4.5 format check; PLATFORM-SKILLS.md has `## Custom agents` + `## Custom skills` headers |
| S7 | All three trinity files exist with `[PLACEHOLDER]` intact; identical top-level heading set |
| S8 | Every pack-.gitignore line present verbatim; dup count accurate |
| S9 | For each non-detected language, no pack file for that language present |
| S10 | Generated prompt contains project absolute path; pack version; existing-docs pointer (if applicable); skill-gap instruction (if applicable); `docs/pack/prompts/pm-chat.md` variant reference |

**Blast-radius sweep** (end of S6 and end of S10):

| Sweep | Expected |
|---|---|
| `grep -r PROMPT-TEMPLATES .claude .codex .gemini docs/pack CLAUDE.md AGENTS.md GEMINI.md agent-run.sh scripts/` | Zero matches |
| Placeholder baseline (diagnostic only) | Baseline recorded |
| Every skill in PLATFORM-SKILLS.md exists in `.claude/skills/`, `.codex/skills/`, `.gemini/skills/` | All present |
| Every prompt file referenced from PM-CHAT.md or trinity exists in `docs/pack/prompts/` | All present |
| Every script referenced from trinity Scripts tables exists in `scripts/` (accounting for conditional removal) | All present |
| Trinity routing-table agent-set parity | Three sets identical |

**Failure modes / exit codes:**

| Code | Meaning |
|---|---|
| 0 | Success or developer declined |
| 10 | `$PACK` invalid |
| 11 | Not a git repo |
| 12 | Working tree not clean |
| 20 | STOP — existing AI config |
| 21–30 | Stage N failure (`20 + N`) |
| 31 | Blast-radius sweep failure |
| 40 | Conditional-removal failure |
| 99 | Internal error (`set -euo pipefail` trap) |

On non-zero exit after S1, script prints diagnostic with stage number,
short explanation, and recovery pointer (`git status`, `git reset --hard
&& git clean -fd`). **No automatic rollback** — rollback requires
knowing pre-init state (only `git status` knows), and automatic rollback
would mask verification failures.

### 7.8 Skill-gap tracking and end-of-run PM chat prompt

**Detection.** After `detect_language_markers` runs, init-project.sh
compares detected languages against the pack skill coverage table
(living in `scripts/lib/detect.sh`):

```bash
PACK_SKILL_COVERAGE="\
swift:apple-architecture-core,swift-best-practices
python:python-architecture,python-best-practices
proto:grpc-patterns
"
```

Languages without coverage are marked `NO COVERAGE` in the preview report
and listed in the end-of-run PM chat prompt.

**End-of-run prompt format** (conditional blocks appear only when
relevant):

```
You are the PM chat for [PROJECT_NAME at <absolute path>].

The AI Agent Config Pack v10.0 has just been installed by
init-project.sh. Please begin your normal kickoff workflow using
Template 1 (docs/pack/prompts/pm-chat.md, variant: kickoff).

{IF existing-project path AND existing docs detected}
This is an existing project with prior documentation. Before
proceeding with the usual context-file placeholder fill-in, read
the following existing documents for context, and confirm with the
developer which other existing docs they want you to read:

  - docs/ARCHITECTURE.md
  - README.md

If the developer points you at additional files (inline design notes,
ADRs, wiki exports, etc.), read those too before generating
architecture content.
{END IF}

{IF skill gaps detected}
init-project.sh detected language/platform markers for which this
pack version has no skill coverage:

  - kotlin
  - typescript

When you complete kickoff, append an entry to
docs/pack/PACK-FEEDBACK.md under the "Language/platform coverage gaps"
section, including:
  - The language or platform name
  - The project stage (from Template 1 kickoff output)
  - A short note on the kinds of guidance the project would benefit from
{END IF}

Run /pm-startup (or your CLI's equivalent), then apply Template 1 with
the developer.
```

Why skill-gap logging runs in the PM chat, not in init-project.sh:

- Context — the PM chat has project-stage, architecture-brief, and
  developer-intent available after kickoff; a shell-script log entry
  would be a shallow note.
- PACK-FEEDBACK.md is PM-chat-owned (per trinity Document locations
  table).
- V9 Lesson 1: one owner per lifecycle stage.

### 7.9 QUICKSTART.md as a three-path router

**Decision.** ~30-line routing doc. No procedural content. One short
paragraph per path pointing to the authoritative guide.

**Full content:**

```markdown
# AI Agent Config Pack — Quick Start

This pack configures Claude Code, Codex CLI, Gemini CLI, and Xcode to
follow your project's architecture rules, coding standards, and
conventions automatically — without repeated prompting.

## Which path are you on?

### New project — you are creating a new repo (no code yet, or only a README)

Follow **[`supporting-docs/SETUP-NEW.md`](supporting-docs/SETUP-NEW.md)**.
You will run `scripts/init-project.sh` from the pack; it copies the agent
files, skills, scripts, and context-file templates into your new project
and prints a PM chat kickoff prompt at the end.

### Existing project — you have an existing project with no AI tooling

Follow **[`supporting-docs/SETUP-EXISTING.md`](supporting-docs/SETUP-EXISTING.md)**.
You will run the same `scripts/init-project.sh`; it detects your existing
source files and docs, previews what it will do, and adds the pack
without overwriting your existing files. The script stops automatically
if any prior AI agent config is detected.

### Pack version upgrade — you already use the pack and want the next major version

Follow the version-specific migration guide in `supporting-docs/`.
For v9 → v10, that is **[`supporting-docs/MIGRATION-v9-to-v10.md`](supporting-docs/MIGRATION-v9-to-v10.md)**.

Version-specific migration guides are always named `MIGRATION-vN-to-vM.md`
and always land in `supporting-docs/`. If you are on an older major
version, first apply the intermediate guide(s) in sequence.

---

See `README.md` for the full version history and repository layout.
```

All procedural content moves to SETUP-NEW.md or SETUP-EXISTING.md.

### 7.10 SETUP-NEW.md outline

Full procedural guide for a new project. ~300–400 lines. Content lifted
from v9 QUICKSTART.md §§1–12 minus the manual-copy steps replaced by
`init-project.sh`, with PROMPT-TEMPLATES.md references updated to
`docs/pack/prompts/pm-chat.md` variants.

Sections:

| # | Heading |
|---|---|
| — | Title + role statement |
| — | Prerequisites (macOS, Xcode, git, GitHub CLI, pack cloned) |
| 1 | Create the GitHub repo (lifted from SETUP_TEMPLATE §1) |
| 2 | (Apple) Create the Xcode project (SETUP_TEMPLATE §2) |
| 3 | **Run `init-project.sh`** — replaces v9 QUICKSTART Steps 1+2+4 |
| 4 | Fill in context file placeholders |
| 5 | (Apple) Fill in Xcode scheme variables |
| 6 | (Apple) Install swift-format |
| 7 | (gRPC) Set up proto code generation |
| 8 | (Apple) Install Xcode companion files |
| 9 | Initial commit |
| 10 | Set up the PM chat (Desktop / Claude Code CLI / Codex CLI / Gemini CLI) — update template references to `docs/pack/prompts/pm-chat.md` variants |
| 11 | Generate SETUP.md and AGENT_KICKOFF.md |
| 12 | Run the architecture kickoff |
| — | Reference (Common agent invocations, Phase routing cheat sheet, What NOT to put in Git) |
| — | Migration note (one-paragraph pointer to `MIGRATION-vN-to-vM.md`) |

### 7.11 SETUP-EXISTING.md outline

Procedural guide for existing projects without AI tooling. ~200–250
lines.

Sections:

| # | Heading |
|---|---|
| — | Title + scope statement ("project with source and/or docs, no prior AI agent config") |
| — | Prerequisites (clean working tree + pack-init branch) |
| 1 | Create the `pack-init` branch |
| 2 | **Run `init-project.sh` and review the preview** — explicit walk-through of every preview section |
| 3 | Review the stage verification output |
| 4 | Fill in context file placeholders |
| 5 | (Apple) Xcode scheme variables |
| 6 | (Apple) Xcode companion files |
| 7 | Commit the pack-init changes |
| 8 | Start the PM chat and paste the kickoff prompt |
| 9 | **PM chat onboarding — existing docs pointer** — key new procedure |
| 10 | PM chat kickoff and architecture assessment |
| 11 | Skill gap follow-up (if applicable) |
| 12 | Continue as normal |
| — | Reference (What NOT to put in Git) |
| — | Migration note |

**Key differences from SETUP-NEW:** clean-working-tree prerequisite;
preview walk-through; existing-docs pointer procedure (Step 9);
architecture reconciliation step (Step 10); skill-gap follow-up
(Step 11).

### 7.12 Migration guide naming convention

**Rule.**
- **Name:** `MIGRATION-vN-to-vM.md` where `N` is the prior major and
  `M` is the new major.
- **Location:** `supporting-docs/` — always.
- **Creation:** one guide per major version upgrade. Patch versions ship
  release notes in `CHANGELOG.md`, not migration guides.
- **Intermediate upgrades:** a project on vN-2 applies the intermediate
  guide first. The pack does not ship direct N-2 → N guides.

**Authoritative home:** `README.md` Repository Layout section gets a
note under `supporting-docs/`:

> Migration guides follow the naming convention
> `MIGRATION-vN-to-vM.md`. They always live in `supporting-docs/` and
> ship with the major version that introduces the destination pack
> version.

References in QUICKSTART.md third paragraph and at the end of
SETUP-NEW.md and SETUP-EXISTING.md point at the README authoritative
entry.

**Automatable migration option.** Per AD-12, the automatable migration
is supplied by `scripts/migrate-v9-to-v10.sh` (Part 6 §6.8) with the
paste-ready prompt pattern (Part 6 §6.9). Future migrations follow the
same pattern: one guide, one script, one paste-ready prompt.

### 7.13 Integration with other BDs

- **BD-045.** BD-045 content lives in trinity files that init-project.sh
  copies verbatim. No init-specific content depends on BD-045.
- **BD-046 prompt reorg.** init-project.sh copies `docs/pack/prompts/`
  as a unit; S6 verification asserts the exact file list from Part 4
  §2.3 plus `PROMPT-AUTHORING.md`.
- **BD-046 custom agents.** init-project.sh never creates `x-` files
  (Part 5 §5.13). Project initial state has `## Custom agents` and
  `## Custom skills` sections with "No custom X defined for this
  project." placeholder rows.
- **BD-046 migration.** init-project.sh refuses to run on a project with
  existing AI config — that case is migration's job. Shared detection
  library (§7.2) ensures both scripts agree on what "AI config present"
  means.

---

## Part 8 — Touch Point Inventory

Replaces V10-PREDESIGN Part 4 in full. Every row is tagged by BD and by
actor. Trinity-rule notes ("TRIO") mark rows where CLAUDE.md / AGENTS.md
/ GEMINI.md edits must move together. Filename rename from Step 11 note 1
(`prompts/README.md` → `PROMPT-AUTHORING.md`) is applied throughout.

### 8.1 Legend

- **BD tags.** BD-044 (init-project & router), BD-045 (capabilities), BD-046 (custom agents & prompt reorg).
- **Actors.** pack chat, init-project.sh, migrate-v9-to-v10.sh, PM chat, developer, CI.
- **Trinity note.** "TRIO" = the row applies identically to CLAUDE.md / AGENTS.md / GEMINI.md in a single commit.

### 8.2 Pack repository — files that change in v10.0

#### 8.2.1 BD-045 — Capabilities pattern (10 files)

| # | File | Change | BD | Actor | Trinity | Source |
|---|---|---|---|---|---|---|
| 1 | `project-template/CLAUDE.md` | New `## Capabilities pattern` section after LSP (Part 3 §3.2); anti-pattern bullet appended (Part 3 §3.2). | BD-045 | pack chat | TRIO | Part 3 |
| 2 | `project-template/AGENTS.md` | Same as row 1. | BD-045 | pack chat | TRIO | Part 3 |
| 3 | `project-template/GEMINI.md` | Same as row 1. | BD-045 | pack chat | TRIO | Part 3 |
| 4 | `project-template/skills/apple-architecture-core/SKILL.md` | New `## Capabilities pattern` section (rules 11–14) after `## Protocol abstractions`; renumber existing 11–23 → 15–27 (Part 3 §3.3). | BD-045 | pack chat | — | Part 3 |
| 5 | `project-template/skills/python-best-practices/SKILL.md` | New section (rules 14–17) after `## Error handling`; renumber 14–32 → 18–36 (Part 3 §3.4). | BD-045 | pack chat | — | Part 3 |
| 6 | `project-template/skills/architecture-review/SKILL.md` | New section (rules 14–17) after `## Abstraction quality`; renumber 14–15 → 18–19 (Part 3 §3.6). | BD-045 | pack chat | — | Part 3 |
| 7 | `project-template/.claude/agents/auditor-architecture.md` | New `Capabilities pattern adherence` scope bullet after `LSP compliance` (Part 3 §3.7). | BD-045 | pack chat | TRIO of three auditor files | Part 3 |
| 8 | `project-template/.codex/agents/auditor-architecture.toml` | Same bullet, plain-bullet inside `developer_instructions = """…"""` (Part 3 §3.7). | BD-045 | pack chat | see row 7 | Part 3 |
| 9 | `project-template/.gemini/agents/auditor-architecture.md` | Same as row 7. | BD-045 | pack chat | see row 7 | Part 3 |
| 10 | (design artifact — Part 3 §3.5 template) | Language-skill placeholder template preserved in V10-DESIGN Part 3 §3.5; applied when a new language skill is added. | BD-045 | future pack chat | — | Part 3 |

**Renumbering sweeps.** Rows 4, 5, 6 shift existing rule numbers. Every
file referencing these skills' rule numbers must be updated. Grep
targets: `rule 1[1-9]` and `rule [23][0-9]` across `project-template/`,
`supporting-docs/`, `maintenance-docs/` during Phase 4.

**Back-reference check.** `audit-methodology/SKILL.md` rule 15
references auditor-architecture scope; Phase 3 confirms no extension is
required or adds one. Surfaced here, not pre-decided.

#### 8.2.2 BD-046 — Prompt template reorganization

**New directory and files (Part 4 §4.2; Step 11 note 1: `PROMPT-AUTHORING.md` rename applied):**

| # | File | Change | BD | Actor | Trinity | Source |
|---|---|---|---|---|---|---|
| 11 | `project-template/docs/pack/prompts/` | Create directory. | BD-046 | pack chat | — | Part 4 §4.2 |
| 12 | `project-template/docs/pack/prompts/coder.md` | New. `agent: coder`; variants `standard`, `fix-cycle`. From T2 + T4. | BD-046 | pack chat | — | Part 4 |
| 13 | `project-template/docs/pack/prompts/reviewer.md` | New. `agent: reviewer`; variants `standard`. From T3. | BD-046 | pack chat | — | Part 4 |
| 14 | `project-template/docs/pack/prompts/tester.md` | New. Variants `standard`. From T5. | BD-046 | pack chat | — | Part 4 |
| 15 | `project-template/docs/pack/prompts/planner.md` | New. Variants `standard`. From T7. | BD-046 | pack chat | — | Part 4 |
| 16 | `project-template/docs/pack/prompts/docs-researcher.md` | New. Variants `standard`. From T6. | BD-046 | pack chat | — | Part 4 |
| 17 | `project-template/docs/pack/prompts/architect.md` | New. Variants `mid-phase` (from T4b, reassigned from coder). | BD-046 | pack chat | — | Part 4 §4.2 |
| 18 | `project-template/docs/pack/prompts/grpc-schema.md` | New. Zero-variant placeholder. | BD-046 | pack chat | — | Part 4 §4.2 |
| 19 | `project-template/docs/pack/prompts/repo-ops.md` | New. Zero-variant placeholder. | BD-046 | pack chat | — | Part 4 §4.2 |
| 20 | `project-template/docs/pack/prompts/auditor.md` | New. Variants `standard` (from T9); trailing T10–12 supersession note. | BD-046 | pack chat | — | Part 4 |
| 21 | `project-template/docs/pack/prompts/pm-chat.md` | New. Variants `kickoff`, `backlog-status-update`, `generate-setup`, `generate-agent-kickoff` (from T1, T8, T13, T14). Reserved `agent: pm-chat`. | BD-046 | pack chat | — | Part 4 §4.2 |
| 22 | `project-template/docs/pack/prompts/PROMPT-AUTHORING.md` | New. "How to use," per-agent exceptions table, self-check rule, pointer to METHODOLOGY.md Prompt Authoring Principles (Part 4 §4.3; Step 11 note 1). | BD-046 | pack chat | — | Part 4 §4.3 |

**Removed file:**

| # | File | Change | BD | Actor | Source |
|---|---|---|---|---|---|
| 23 | `supporting-docs/PROMPT-TEMPLATES.md` | **Delete** at v10.0. Content redistributed per rows 12–22; Prompt Authoring Principles already in METHODOLOGY.md. No orphaned templates (Step 11 note 2). | BD-046 | pack chat | Part 4 §4.8 |

**Operational stale-reference sweep (V9 Lesson 4; Part 4 §4.8):**

| # | File | Change | BD | Actor | Trinity | Source |
|---|---|---|---|---|---|---|
| 24 | `project-template/docs/pack/PM-CHAT.md` | Remove PROMPT-TEMPLATES.md row from File-access-strategy; add `docs/pack/prompts/<agent>.md` row + directory-listing row for seven detection dirs (Part 5 §5.10). Drop PROMPT-TEMPLATES.md from mcp-local-rag recommendation. **Combine with row 38.** | BD-046 | pack chat | — | Part 4 §4.8, Part 5 §5.10 |
| 25 | `project-template/skills/pm-startup/SKILL.md` | Drop `docs/pack/PROMPT-TEMPLATES.md` from Step 4 RAG check; METHODOLOGY.md retained (Part 4 §4.7). | BD-046 | pack chat | — | Part 4 §4.7 |
| 26 | `project-template/CLAUDE.md` | Document-locations table `docs/pack/` row — replace `PROMPT-TEMPLATES.md` literal with `prompts/` directory. **Combine with rows 1 and 39.** | BD-046 | pack chat | TRIO | Part 4 §4.8 |
| 27 | `project-template/AGENTS.md` | Same as row 26. **Combine with rows 2 and 40.** | BD-046 | pack chat | TRIO | Part 4 §4.8 |
| 28 | `project-template/GEMINI.md` | Same as row 26. **Combine with rows 3 and 41.** | BD-046 | pack chat | TRIO | Part 4 §4.8 |
| 29 | `project-template/README.md` | Sweep for any PROMPT-TEMPLATES.md file-listing or path reference. | BD-046 | pack chat | — | Part 4 §4.8 |
| 30 | `supporting-docs/METHODOLOGY.md` | Replace PROMPT-TEMPLATES.md location references with `docs/pack/prompts/<agent>.md`. Do NOT modify "Prompt Authoring Principles." **Combine with rows 43 and 48.** | BD-046 | pack chat | — | Part 4 §4.8 |
| 31 | `QUICKSTART.md` | Full rewrite as three-path router (Part 7 §7.9). PROMPT-TEMPLATES.md reference dropped as part of rewrite. **Also BD-044 row 54.** | BD-044, BD-046 | pack chat | — | Part 4 §4.8, Part 7 §7.9 |
| 32 | `supporting-docs/CLI-PM-SETUP.md` | Sweep PROMPT-TEMPLATES.md references; sweep `QUICKSTART.md Step N` number references. | BD-044, BD-046 | pack chat | — | Part 4 §4.8, Part 7 §7.13 |
| 33 | `supporting-docs/SETUP_TEMPLATE.md` | (a) Replace `cp -r` + manual skill distribution with `bash "$PACK/scripts/init-project.sh"`; (b) rewrite `QUICKSTART.md Step N` references to SETUP-NEW.md section names; (c) replace PROMPT-TEMPLATES.md references. | BD-044, BD-046 | pack chat | — | Part 4 §4.8, Part 7 §7.13 |
| 34 | `supporting-docs/DEPENDENCIES.md` | Only if it enumerates PROMPT-TEMPLATES.md; otherwise no-op. | BD-046 | pack chat | — | Part 4 §4.8 |
| 35 | `supporting-docs/MIGRATION-v8-to-v9.md` | No update required; historical. Optional one-line pointer to MIGRATION-v9-to-v10.md. | — (annotate only) | pack chat | — | Part 6 |

**Annotate but do not mutate (historical records):**

| # | File | Annotation | BD | Actor | Source |
|---|---|---|---|---|---|
| 36 | `maintenance-docs/V9-DESIGN.md` | v10 supersession note next to references to PROMPT-TEMPLATES.md as a shipping artifact; pointer to `project-template/docs/pack/prompts/`. Annotate Decision 7 to point at V10-DESIGN Part 5 custom-agent mechanism. Do not silently rewrite v9 content (V9 Lesson 4). | BD-046 | pack chat | Part 4 §4.8, Part 5 §5.13 |
| 37 | `maintenance-docs/V9-AUDIT-REPORT.md` (if present) | Same treatment as row 36. | BD-046 | pack chat | Part 4 §4.8 |

**No-action historical files** (listed to prevent accidental edits):
`maintenance-docs/origins/*`, `maintenance-docs/guides/*`,
`maintenance-docs/GEMINI-CLI-ANALYSIS.md`,
`maintenance-docs/ANDROID-ANALYSIS.md`, `CHANGELOG.md` (except the v10.0
entry, row 70), resolved BACKLOG items (BD-027, BD-028, BD-029, BD-038).

#### 8.2.3 BD-046 — Custom agent and skill support

| # | File | Change | BD | Actor | Trinity | Source |
|---|---|---|---|---|---|---|
| 38 | `project-template/docs/pack/PM-CHAT.md` | Add `## Pack agent roster` section (Part 5 §5.3); add `## Custom agent and skill workflow` section (Part 5 §5.10); add agent-report-file behavioral rule (Part 4 §4.6); file-access-strategy table additions. **Combine with row 24.** | BD-046 | pack chat | — | Part 5 §5.3, §5.10 |
| 39 | `project-template/CLAUDE.md` | Add `### Custom agents` sub-section at end of Phase routing table (Part 5 §5.6). **Combine with rows 1 and 26.** | BD-046 | pack chat | TRIO | Part 5 §5.6 |
| 40 | `project-template/AGENTS.md` | Same as row 39. **Combine with rows 2 and 27.** | BD-046 | pack chat | TRIO | Part 5 §5.6 |
| 41 | `project-template/GEMINI.md` | Same as row 39. **Combine with rows 3 and 28.** | BD-046 | pack chat | TRIO | Part 5 §5.6 |
| 42 | `project-template/docs/pack/PLATFORM-SKILLS.md` | Add `## Custom agents` + `## Custom skills` sections immediately after `## Full skill inventory` (Part 5 §5.2). Placeholder rows. | BD-046 | pack chat | — | Part 5 §5.2 |
| 43 | `supporting-docs/METHODOLOGY.md` | Add Procedure 5 (sub-procedures 5.1–5.6) at end of Part 7 (Part 5 §5.7). **Combine with rows 30 and 48.** | BD-046 | pack chat | — | Part 5 §5.7 |

#### 8.2.4 BD-046 — Migration v9.3 → v10.0

| # | File | Change | BD | Actor | Trinity | Source |
|---|---|---|---|---|---|---|
| 44 | `supporting-docs/MIGRATION-v9-to-v10.md` | New guide; 15 sections (Part 6 §6.9). | BD-046 | pack chat | — | Part 6 §6.9 |
| 45 | `scripts/migrate-v9-to-v10.sh` | New migration script; eight stages S0–S7 (Part 6 §6.8); sources `scripts/lib/detect.sh`. | BD-046 | pack chat | — | Part 6 §6.8 |
| 46 | `scripts/merge-platform-skills.py` | New helper; positional splice at first `## Custom agents` or `## Custom skills` heading (Part 6 §6.6). | BD-046 | pack chat | — | Part 6 §6.6 |
| 47 | `scripts/merge-trinity.py` | New helper; two splices per trinity file (`### Custom agents` sub-section + `**Active skills:**` line) (Part 6 §6.6). | BD-046 | pack chat | — | Part 6 §6.6 |
| 48 | `supporting-docs/METHODOLOGY.md` | Add Procedure 5-R (reconciliation) alongside Procedure 5 (Part 6 §6.5). **Combine with rows 30 and 43.** | BD-046 | pack chat | — | Part 6 §6.5 |

#### 8.2.5 BD-044 — init-project.sh and router

| # | File | Change | BD | Actor | Trinity | Source |
|---|---|---|---|---|---|---|
| 49 | `scripts/init-project.sh` | New. Detection + preview-and-confirm + 11 stages S0–S10 + inline verification (Part 7 §7.6–7.7). Pack-repo `scripts/`. | BD-044 | pack chat | — | Part 7 |
| 50 | `scripts/lib/` | New directory in pack-repo `scripts/`. | BD-044 | pack chat | — | Part 7 §7.2 |
| 51 | `scripts/lib/detect.sh` | New shared detection library (functions per Part 7 §7.2). | BD-044 | pack chat | — | Part 7 §7.2 |
| 52 | `supporting-docs/SETUP-NEW.md` | New. ~300–400 lines; section list per Part 7 §7.10. | BD-044 | pack chat | — | Part 7 §7.10 |
| 53 | `supporting-docs/SETUP-EXISTING.md` | New. ~200–250 lines; section list per Part 7 §7.11. | BD-044 | pack chat | — | Part 7 §7.11 |
| 54 | `QUICKSTART.md` | Full rewrite as ~30-line three-path router (Part 7 §7.9). **Combine with row 31.** | BD-044 | pack chat | — | Part 7 §7.9 |
| 55 | `README.md` | Repository Layout updates: add `scripts/lib/`, `scripts/init-project.sh`, `scripts/migrate-v9-to-v10.sh`, `scripts/merge-*.py`, `supporting-docs/SETUP-NEW.md`, `SETUP-EXISTING.md`, `MIGRATION-v9-to-v10.md`; migration-guide naming convention note (Part 7 §7.12). **Combine with row 68.** | BD-044, BD-046 | pack chat | — | Part 7 §7.12 |

#### 8.2.6 validate-pack.py and CI workflow updates

| # | File | Change | BD | Actor | Source |
|---|---|---|---|---|---|
| 56 | `scripts/validate-pack.py` | Check 6 — prompts-directory format (Part 4 §4.5). | BD-046 | pack chat | Part 4 §4.5 |
| 57 | `scripts/validate-pack.py` | Check 7 — pack-agent-roster consistency (Part 5 §5.3). | BD-046 | pack chat | Part 5 §5.11 |
| 58 | `scripts/validate-pack.py` | Check 8 — reserved `x-` prefix (Part 5 §5.5). | BD-046 | pack chat | Part 5 §5.11 |
| 59 | `scripts/validate-pack.py` | Check 9 — BD-044 structure (Part 7 §7.13). | BD-044 | pack chat | Part 7 §7.13 |
| 60 | `scripts/validate-pack.py` | Existing Check 1 — SKILL.md frontmatter, sanity-only after BD-045 renumbering. | BD-045 | pack chat | Part 3 |
| 61 | `.github/workflows/validate-pack.yml` | No workflow-level change required if checks 6–9 added inside the existing `python3 scripts/validate-pack.py` invocation; re-verify clean run on v10-dev. | BD-044, BD-046 | pack chat | Part 5 §5.11, Part 7 §7.13 |

#### 8.2.7 Pack-operational files (version bookkeeping)

| # | File | Change | BD | Actor | Source |
|---|---|---|---|---|---|
| 62 | `maintenance-docs/V10-DESIGN.md` | **This document.** Status APPROVED at Step 13. | — | pack chat | V10-DESIGN-PROCESS-PLAN Steps 11–13 |
| 63 | `maintenance-docs/V10-PREDESIGN.md` | Supersession banner pointing to V10-DESIGN.md; body retained (V9 Lesson 4). | — | pack chat | V10-DESIGN-PROCESS-PLAN Step 13 |
| 64 | `BACKLOG.md` | Clear BD-044/045/046 blockers at Step 13; set Resolved at v10.0 ship. | — | pack chat | V10-DESIGN-PROCESS-PLAN Step 13 |
| 65 | `README.md` | Add v10.0 row to version table at ship time. **Combine with row 55.** | — | pack chat | CLAUDE.md versioning rules |
| 66 | `CHANGELOG.md` | Add v10.0 entry at ship time. | — | pack chat | CLAUDE.md versioning rules |

### 8.3 Files in a v10 project (produced by runtime actors)

These rows are not pack-repo edits — they are what init-project.sh,
migrate-v9-to-v10.sh, or the PM chat produces in a project over time.

| # | Project path | Change | BD | Actor |
|---|---|---|---|---|
| 67 | `docs/pack/prompts/` + 10 files + `PROMPT-AUTHORING.md` | Copied from pack template. | BD-046 | init-project.sh (new); migrate-v9-to-v10.sh S4 (v9.3 upgrade) |
| 68 | `docs/pack/prompts/_v9-backup.md` | Conditional — only when project's v9.3 PROMPT-TEMPLATES.md diverges from baseline. PM chat consumes and deletes via Procedure 5-R. | BD-046 | migrate-v9-to-v10.sh S6 (create); PM chat (delete) |
| 69 | `docs/pack/PROMPT-TEMPLATES.md` (v9.3 file) | **Deleted** at migration S6. | BD-046 | migrate-v9-to-v10.sh S6 |
| 70 | `.claude/agents/x-<name>.md`, `.codex/agents/x-<name>.toml`, `.gemini/agents/x-<name>.md` | Created per Procedure 5.1. | BD-046 | PM chat |
| 71 | `.claude/skills/x-<name>/SKILL.md`, `.codex/skills/x-<name>/SKILL.md`, `.gemini/skills/x-<name>/SKILL.md` | Created per Procedure 5.2. | BD-046 | PM chat |
| 72 | `docs/pack/prompts/x-<name>.md` | Created per Procedure 5.1. Same Part 4 §4.5 format as pack prompts. | BD-046 | PM chat |
| 73 | `docs/pack/PLATFORM-SKILLS.md` `## Custom agents` / `## Custom skills` rows | Rows added per Procedure 5.1 / 5.2. Project-owned section. | BD-046 | PM chat |
| 74 | CLAUDE.md / AGENTS.md / GEMINI.md `### Custom agents` sub-section rows | Rows added per Procedure 5.1. TRIO. Project-owned sub-section. | BD-046 | PM chat |
| 75 | `docs/pack/PACK-FEEDBACK.md` | Skill-gap entry appended when init-project.sh reports a coverage gap and PM chat runs kickoff. | BD-044 | PM chat |
| 76 | `.gitignore` | Merged at init-project.sh S8; `.pack-migration-backup/` appended at migration S0. | BD-044, BD-046 | init-project.sh; migrate-v9-to-v10.sh |
| 77 | `.pack-migration-backup/v9.3-to-v10.0/*` | Migration backup directory; gitignored. | BD-046 | migrate-v9-to-v10.sh |

**Removed from V10-PREDESIGN Part 4.** The row
`project-template/.codex/config.toml — Custom agent registration
documentation` is removed per Part 5 §5.4. The Part 5 workflow sub-step
"PM chat adds `[agents.x_name]` entry" is removed.

### 8.4 Per-BD sequencing (for Phase 3)

Per AD-10 OQ-10 resolution: **BD-045 → BD-046 → BD-044.**

- **BD-045 commit batch.** Rows 1–9 (10 is a design artifact).
- **BD-046 commit batches.** Rows 11–23 (prompt reorg new + remove); rows
  24–37 (stale-reference sweep + annotations); rows 38–43 (custom agent
  sections + PLATFORM-SKILLS + Procedure 5); rows 44–48 (migration
  script + guide + Procedure 5-R); rows 56–58, 60–61 (validate-pack 6–8).
- **BD-044 commit batch.** Rows 49–55 (init-project.sh + lib + SETUP-NEW
  + SETUP-EXISTING + QUICKSTART + README layout); rows 59, 61 (validate-
  pack Check 9 + workflow).
- **Cross-BD coordination rows.** Marked "Combine with…" in §8.2 — the
  trinity files get BD-045 LSP-section edits, BD-046 Document-locations
  edits, and BD-046 phase-routing custom-agents edits in a single commit
  to preserve trinity rule cleanly (rows 1/26/39, 2/27/40, 3/28/41).
  METHODOLOGY.md gets PROMPT-TEMPLATES.md sweep + Procedure 5 + Procedure
  5-R in one commit (rows 30, 43, 48). QUICKSTART.md rewrite unifies
  BD-044 rewrite + BD-046 PROMPT-TEMPLATES.md sweep (row 31/54). README.md
  unifies BD-044 layout + version-table row (row 55/65).

Phase 3 implementation planning resolves exact commit boundaries. This
inventory ensures no file is forgotten and every cross-BD dependency is
surfaced.

### 8.5 Trinity-rule integrity audit

| Section | BD-045 edit | BD-046 edit | Notes |
|---|---|---|---|
| `## Capabilities pattern` (new) | Rows 1, 2, 3 | — | TRIO |
| Anti-patterns universal list | Rows 1, 2, 3 | — | TRIO |
| `## Document locations` / docs/pack row | — | Rows 26, 27, 28 | TRIO |
| `## Phase routing` → new `### Custom agents` sub-section | — | Rows 39, 40, 41 | TRIO |
| `## Skill loading` → Active skills line | — | Preserved by migration; no v10 pack edit | Project-owned |
| `auditor-architecture` scope bullet | Rows 7, 8, 9 | — | TRIO (Codex formatting deviation per Part 3 §3.7) |

No asymmetry introduced by v10. Every trinity-level change is symmetric
by design.

### 8.6 Stale-reference sweep — consolidated grep targets

Run during Phase 4 verification:

```bash
# PROMPT-TEMPLATES.md sweep
grep -rn "PROMPT-TEMPLATES" \
    project-template/ supporting-docs/ \
    maintenance-docs/V9-DESIGN.md maintenance-docs/V9-AUDIT-REPORT.md \
    QUICKSTART.md README.md PACK-CHAT.md PACK-AGENTS.md \
    CLAUDE.md AGENTS.md GEMINI.md

# QUICKSTART.md Step-N reference sweep
grep -rnE "QUICKSTART\.md\s+Step\s+[0-9]+" \
    project-template/ supporting-docs/ maintenance-docs/

# cp -r setup-command sweep
grep -rnE "cp\s+-r\s+.*project-template" \
    supporting-docs/ maintenance-docs/

# Codex config.toml custom-agent entry sweep (Part 5 §5.4 removal target)
grep -rnE "\[agents\.(x_|x-)" \
    project-template/ supporting-docs/ maintenance-docs/

# Reserved x- prefix in pack template (must return zero)
ls project-template/.claude/agents/ project-template/.codex/agents/ \
   project-template/.gemini/agents/ project-template/skills/ \
   project-template/docs/pack/prompts/ 2>/dev/null | grep "^x-"

# BD-045 renumbering sweep
grep -rnE "rule [1-9][0-9]" \
    project-template/skills/apple-architecture-core/ \
    project-template/skills/python-best-practices/ \
    project-template/skills/architecture-review/ \
    project-template/ supporting-docs/ maintenance-docs/
```

Expected results for each sweep are encoded in Part 10 verification
tests.

---

## Part 9 — Migration Testing Matrix

Enumerates the Cartesian product of V10-PREDESIGN Part 10 dimensions.
Each cell is **critical-path** (CP), **spot-check** (SC), **deferred**
(DEF), or **out-of-scope** (OOS).

### 9.1 Dimensions

| Dimension | Values |
|---|---|
| **D1 — Project type** | P1 Swift-only, P2 Python-only, P3 Swift+Python monorepo, P4 Swift+gRPC, P5 existing project with no AI (P5-Swift, P5-Python, P5-monorepo, P5-Kotlin gap case, P5-bare) |
| **D2 — Migration path** | M1 v9.3 → v10.0, M2 new project via init-project.sh, M3 existing project via init-project.sh |
| **D3 — PM chat tool** | T1 Claude Code CLI, T2 Claude Desktop, T3 Codex CLI, T4 Gemini CLI |
| **D4 — Custom file state** | C1 none, C2 agents only, C3 skills only, C4 agents + skills |

Full Cartesian = 5 × 3 × 4 × 4 = 240 cells. Pruning (C2–C4 apply only to
M1 or post-install M2/M3) collapses to ~60 meaningful cells.

### 9.2 Critical-path rules

- At least one cell per D3 (PM chat tool) is CP.
- At least one cell per BD-scoped outcome is CP (custom agent created,
  custom skill created, init new, init existing, migration).
- Every CP cell cross-references a Part 10 verification test.

### 9.3 M1 (v9.3 → v10.0) matrix

| Project | T1·C1 | T1·C2 | T1·C3 | T1·C4 | T2·C1 | T2·C2 | T3·C1 | T3·C2 | T4·C1 | T4·C4 |
|---|---|---|---|---|---|---|---|---|---|---|
| P1 Swift-only | **CP**[V-M1-01] | CP[V-M1-02] | SC[V-M1-03] | CP[V-M1-04] | CP[V-M1-05] | SC[V-M1-06] | SC[V-M1-07] | SC[V-M1-08] | CP[V-M1-09] | DEF |
| P2 Python-only | SC[V-M1-10] | DEF | DEF | SC[V-M1-11] | DEF | DEF | CP[V-M1-12] | DEF | DEF | DEF |
| P3 Swift+Python | CP[V-M1-13] | DEF | DEF | SC[V-M1-14] | DEF | DEF | DEF | DEF | DEF | DEF |
| P4 Swift+gRPC | SC[V-M1-15] | DEF | DEF | DEF | DEF | DEF | DEF | DEF | DEF | DEF |
| P5 (N/A for M1) | OOS | OOS | OOS | OOS | OOS | OOS | OOS | OOS | OOS | OOS |

Rationale:
- P5 (`existing-source with no AI`) is by definition not-yet-pack → OOS
  for M1 (which requires v9.3 baseline).
- C2/C3/C4 require a project that has run Procedure 5; for v10.0 launch,
  at least P1·T1·C2 and P1·T1·C4 are CP.
- T4·C4 deferred because Gemini CLI custom-agent creation is structurally
  identical to Claude Code at the PM-chat layer; T4·C1 + a post-migration
  Procedure 5.1 exercise on Gemini suffices.

### 9.4 M2 (new project via init-project.sh) matrix

| Project | T1 | T2 | T3 | T4 |
|---|---|---|---|---|
| P1 Swift-only (new) | **CP**[V-M2-01] | CP[V-M2-02] | SC[V-M2-03] | CP[V-M2-04] |
| P2 Python-only (new) | CP[V-M2-05] | SC[V-M2-06] | SC[V-M2-07] | DEF |
| P3 Swift+Python (new) | CP[V-M2-08] | DEF | DEF | DEF |
| P4 Swift+gRPC (new) | SC[V-M2-09] | DEF | DEF | DEF |
| P5 (N/A for M2) | OOS | OOS | OOS | OOS |

C2/C3/C4 N/A for M2 (fresh project has no custom files).

### 9.5 M3 (existing project via init-project.sh) matrix

| Project | T1 | T2 | T3 | T4 |
|---|---|---|---|---|
| P5-Swift (existing Swift, no AI) | **CP**[V-M3-01] | SC[V-M3-02] | SC[V-M3-03] | CP[V-M3-04] |
| P5-Python | CP[V-M3-05] | DEF | SC[V-M3-06] | DEF |
| P5-monorepo (Swift+Python) | CP[V-M3-07] | DEF | DEF | DEF |
| P5-Kotlin (skill-gap scenario) | CP[V-M3-08] | DEF | DEF | DEF |
| P5-bare (docs only) | SC[V-M3-09] | DEF | DEF | DEF |
| P1–P4 (already-configured) | OOS | OOS | OOS | OOS |
| P5 partial AI config | CP[V-M3-10] (stop) | DEF | DEF | DEF |

### 9.6 Per-tool coverage summary

| Tool | CP cells |
|---|---|
| T1 Claude Code CLI | V-M1-01, V-M1-04, V-M2-01, V-M3-01, V-M3-10 |
| T2 Claude Desktop | V-M1-05, V-M2-02 |
| T3 Codex CLI | V-M1-12, V-M2-03 / V-M2-07 |
| T4 Gemini CLI | V-M1-09, V-M2-04, V-M3-04 |

### 9.7 Per-BD-scoped outcome coverage

| Outcome | CP cell | Primary Part 10 test |
|---|---|---|
| Custom agent created | P1·T1·C2 (M1) | V-PM5-01 |
| Custom skill created | P1·T1·C3 (M1) | V-PM5-02 |
| init-project.sh new | P1·T1 M2 | V-INIT-NEW-01 |
| init-project.sh existing | P5-Swift·T1 M3 | V-INIT-EXIST-01 |
| Migration v9.3 → v10.0 | P1·T1·C1 M1 | V-M1-01 |

### 9.8 Deferred and out-of-scope rationale

**Deferred (documented but not tested):**
- T4 × C4 — Gemini custom-file migration. Tool-agnostic risk covered
  elsewhere.
- P4 × non-T1 — gRPC scaffolding tested structurally.
- P2 × C2/C3 on M1 — custom-file handling is language-agnostic.
- P5 partial AI config on T2/T3/T4 — stop-condition logic is tool-
  independent.

**Out-of-scope:**
- M1 × P5 — impossible (P5 has no AI tools).
- M2 × P5 — impossible (P5 is existing).
- M3 × P1–P4 (already-configured) — stop-condition-only; covered by
  V-M3-10 on T1.

### 9.9 Coverage totals

| Category | Count |
|---|---|
| CP cells | 16 |
| SC cells | 17 |
| Deferred | 25 |
| Out-of-scope | ~150 |
| Total meaningful | 58 |

The 16 CP cells are the Phase 4 mandatory test set. Spot-check cells run
where capacity allows; their failures surface as PACK-FEEDBACK.md
entries, not commit blockers.

---

## Part 10 — Verification Plan

Every v10 deliverable is proven correct by at least one test defined
below. Tests name setup, action, pass condition, and fail condition.
Every Part 9 critical-path cell cross-references a test here.

### 10.1 CI validation tests (V-CI-*)

Run by the `Validate Pack` GitHub Actions workflow on every push.

| ID | Scope | Setup | Action | Pass | Fail |
|---|---|---|---|---|---|
| V-CI-01 | Check 6 — prompts-dir format | Pack ships 10 per-agent prompt files + PROMPT-AUTHORING.md per Part 4 §4.5 | `python3 scripts/validate-pack.py` | All 10 prompt files pass frontmatter + variant-heading checks | Missing frontmatter; wrong `agent:` stem; orphan variant slug; orphan `## Variant:` heading |
| V-CI-02 | Check 6 — negative cases | Deliberately commit: (a) `agent: reviewer` in `coder.md`; (b) missing `---`; (c) `variants: [foo]` with no matching H2 | validate-pack.py | Each defect triggers specific failure message | Silent pass |
| V-CI-03 | Check 7 — pack-roster consistency | Canonical PM-CHAT.md `## Pack agent roster` matches `.claude/agents/*.md` stems | validate-pack.py | Roster set equals Claude agents stems | Drift |
| V-CI-04 | Check 7 — negative | Temp-add a roster entry with no agent file OR remove an entry that has a file | validate-pack.py | Fails with mismatch message | Silent pass |
| V-CI-05 | Check 8 — reserved `x-` prefix | Pack ships no `x-` files in the seven scan locations | validate-pack.py | Zero `x-` files in pack template | Any `x-` file in pack template |
| V-CI-06 | Check 8 — negative | Temp-commit `project-template/.claude/agents/x-test.md` OR `project-template/skills/x-test/SKILL.md` OR `project-template/docs/pack/prompts/x-test.md` | validate-pack.py | Fails naming the file | Silent pass |
| V-CI-07 | Check 9 — BD-044 structure | Pack has init-project.sh (exec), lib/detect.sh (functions from Part 7 §7.2), QUICKSTART + SETUP-NEW + SETUP-EXISTING + MIGRATION-v9-to-v10, README Repository Layout mentions `scripts/lib/` and naming convention | validate-pack.py | All five checks pass | Any missing file or layout note |
| V-CI-08 | Check 1 after BD-045 renumbering | After BD-045 edits to 3 skills | Check 1 | No frontmatter drift | Drift |
| V-CI-09 | Check 2 after BD-045 edit to auditor-architecture.toml | After insertion | Check 2 | TOML parses | Parse error |
| V-CI-10 | Check 5 — agent-count parity | Any BD-045/046 commit | Check 5 | Three dirs have identical stem sets | Divergence |

### 10.2 Manual migration tests (V-M1-*)

Shared setup: a v9.3 fixture project (tag `fixture-v9.3-<type>`). Pack
repo at v10-dev or v10.0 tag. `PACK=/path/to/pack`; working tree clean.

| ID | Part 9 cell | Setup | Action | Pass | Fail |
|---|---|---|---|---|---|
| V-M1-01 | P1·T1·C1 | Swift-only fixture, no customizations, Claude Code CLI | `bash "$PACK/scripts/migrate-v9-to-v10.sh"`; inspect each sentinel; commit; run `validate.sh` | All 7 sentinels present; report `customization: none`; `docs/pack/prompts/` has 10 files + PROMPT-AUTHORING.md passing Check 6; trinity has BD-045 section + `### Custom agents` stub; monolith deleted; no `_v9-backup.md`; validate.sh passes | Any stage fails; expected file missing; unexpected file modified |
| V-M1-02 | P1·T1·C2 | Fixture + seeded `x-deployer` agent trio | As V-M1-01 | All three `x-deployer.*` files byte-identical; report lists them under preserved-x-files | Any byte change |
| V-M1-03 | P1·T1·C3 | Fixture + seeded `x-brokerage-api` skill (three SKILL.md files) | As V-M1-01 | All three skill files byte-identical; dirs preserved | Any change |
| V-M1-04 | P1·T1·C4 | Fixture + `x-deployer` agent + `x-brokerage-api` skill + `x-deployer.md` prompt | As V-M1-01 | All seven `x-` artifacts byte-identical | Any change |
| V-M1-05 | P1·T2·C1 | As V-M1-01 but via Claude Desktop + filesystem MCP using Part 6 §6.9 paste prompt | Paste prompt; Desktop executes with per-stage pauses | Each pause renders; final state = V-M1-01 | Desktop cannot drive; pause not rendered |
| V-M1-06 | P1·T2·C2 | V-M1-05 + one custom agent | As V-M1-05 + preservation check | Preserved | Changed |
| V-M1-07 | P1·T3·C1 | Codex CLI drives migration via prompt | Paste prompt | Matches V-M1-01 | Codex failure |
| V-M1-08 | P1·T3·C2 | Codex + one custom agent | As V-M1-07 + preservation | Preserved | Changed |
| V-M1-09 | P1·T4·C1 | Gemini CLI drives migration | Paste prompt | Matches V-M1-01 | Gemini failure |
| V-M1-10 | P2·T1·C1 | Python-only fixture | Migration | Python-specific scripts present & executable | Missing / non-executable |
| V-M1-11 | P2·T1·C4 | Python + `x-` agent + skill + prompt | Migration | All `x-` preserved | Change |
| V-M1-12 | P2·T3·C1 | Python fixture on Codex | Migration | Matches V-M1-10 | Codex failure |
| V-M1-13 | P3·T1·C1 | Swift+Python monorepo | Migration | Both language scripts present | Either missing |
| V-M1-14 | P3·T1·C4 | Monorepo + `x-` agent + skill | Migration | All preserved; monorepo scripts intact | Regression |
| V-M1-15 | P4·T1·C1 | Swift+gRPC fixture | Migration | proto-gen.sh + validate-proto.sh present; proto/ untouched | Regression |

### 10.3 Rollback rehearsal (V-M1-ROLLBACK)

| ID | Setup | Action | Pass | Fail |
|---|---|---|---|---|
| V-M1-ROLLBACK | Completed V-M1-01 on `migration-v9-to-v10` branch | Execute Part 6 §6.7 rollback verbatim | Post-rollback tree byte-identical to `fixture-v9.3-swift-only` (`git diff` empty); PROMPT-TEMPLATES.md present; no `docs/pack/prompts/`; trinity matches v9.3 | Any residual v10 artifact; any v9.3 file missing |

### 10.4 Customized-PROMPT-TEMPLATES.md tests (V-M1-CUSTOM-*)

| ID | Setup | Action | Pass | Fail |
|---|---|---|---|---|
| V-M1-CUSTOM-01 | Fixture with monolith identical to v9.3 baseline | Migration | Report `customization: none`; no `_v9-backup.md`; monolith deleted | Backup written in error; monolith retained |
| V-M1-CUSTOM-02 | Fixture with one-sentence custom addition in Template 4 | Migration | Report `customization: divergence detected; reconciliation flag set`; `_v9-backup.md` created byte-equal to original; monolith deleted | Backup absent; customization overwritten |
| V-M1-CUSTOM-03 | After V-M1-CUSTOM-02 | PM chat first run detects `_v9-backup.md`; runs Procedure 5-R | PM chat surfaces customization with proposed `coder.md ## Variant: fix-cycle` placement; writes splice on approval; deletes backup | PM chat ignores backup; auto-merges without approval; or deletes without writing splice |

### 10.5 init-project.sh new-project tests (V-INIT-NEW-*)

| ID | Part 9 cell | Setup | Action | Pass | Fail |
|---|---|---|---|---|---|
| V-INIT-NEW-01 | V-M2-01 | Fresh `git init` + optional README | `bash "$PACK/scripts/init-project.sh"`; confirm preview; run | Stage checks §7.7 pass; blast-radius sweep zero matches for PROMPT-TEMPLATES; trinity placeholders intact; 10 prompt files + PROMPT-AUTHORING.md; kickoff prompt printed with absolute path | Stage assertion fires; sweep finds stale reference; missing file |
| V-INIT-NEW-02 | V-M2-02 | Same fixture, Claude Desktop + filesystem MCP | init-project.sh via shell; kickoff prompt pasted in Desktop | Prompt executes | Desktop incompatibility |
| V-INIT-NEW-03 | V-M2-04 | Gemini CLI | Same | Kickoff proceeds on Gemini | Gemini failure |
| V-INIT-NEW-04 | V-M2-05 | Fresh + `pyproject.toml` seeded | init-project.sh | Classified existing-source Python; conditional removal keeps Python, removes Swift/Proto | Python-specific files missing |
| V-INIT-NEW-05 | V-M2-08 | Fresh + `Package.swift` + `pyproject.toml` | init-project.sh | Classified monorepo; both language sets kept | Either pruned |

### 10.6 init-project.sh existing-project tests (V-INIT-EXIST-*)

| ID | Part 9 cell | Setup | Action | Pass | Fail |
|---|---|---|---|---|---|
| V-INIT-EXIST-01 | V-M3-01 | Real Swift project, docs/ARCHITECTURE.md, no AI config | init-project.sh | Preview lists existing files under [SKIP]; [MERGE] .gitignore; [ADD] pack; existing-docs pointer in prompt; developer transition notice; no skip-list file modified | Skip-list file changed; pointer missing |
| V-INIT-EXIST-02 | V-M3-04 | Same, Gemini CLI | init-project.sh; Gemini reads prompt | Kickoff proceeds; pointer honored | Regression |
| V-INIT-EXIST-03 | V-M3-05 | Existing Python project | init-project.sh | existing-source Python; Swift files pruned | Any Python touched; Swift remains |
| V-INIT-EXIST-04 | V-M3-07 | Existing Swift+Python monorepo | init-project.sh | Both detected; monorepo files kept | Either pruned |
| V-INIT-EXIST-05 | V-M3-08 | Kotlin project (skill-gap scenario) | init-project.sh | Kotlin detected; skill coverage shows NO COVERAGE; prompt contains skill-gap instruction; PM chat appends PACK-FEEDBACK | Gap not reported |
| V-INIT-EXIST-06 | V-M3-09 | README + docs/ only | init-project.sh | Classified `existing-bare`; pointer to existing docs in prompt; source-free does not trigger stop | Wrong class |
| V-INIT-EXIST-07 | V-M3-10 | Existing project with `.claude/` present | init-project.sh | Stop fires; exit 20; no files written | Script proceeds |

### 10.7 Inline verification per-stage tests (V-INIT-VERIFY-*)

Maps to Part 7 §7.7 per-stage assertions and blast-radius sweep.

| ID | Stage | Check |
|---|---|---|
| V-INIT-VERIFY-01 | S1 | All expected dirs exist, no extras |
| V-INIT-VERIFY-02 | S2 | Agent counts equal pack counts; trinity stem parity |
| V-INIT-VERIFY-03 | S4 | Each pack skill present in three tool dirs; Claude body byte-identical |
| V-INIT-VERIFY-04 | S5 | Scripts present and executable; `agent-run.sh` executable |
| V-INIT-VERIFY-05 | S6 | 10 prompt files + PROMPT-AUTHORING.md + 4 pack docs; each prompt passes Check 6; PLATFORM-SKILLS.md has Custom sections |
| V-INIT-VERIFY-06 | S7 | Trinity present with placeholders; identical top-level heading set |
| V-INIT-VERIFY-07 | S8 | Pack-.gitignore lines present verbatim; dup count accurate |
| V-INIT-VERIFY-08 | S9 | For each non-detected language, no pack file for that language |
| V-INIT-VERIFY-09 | S10 | Prompt has project path, pack version, existing-docs pointer (if applicable), skill-gap instruction (if applicable), prompts/pm-chat.md variant reference |
| V-INIT-VERIFY-10 | Blast-radius | `grep -r PROMPT-TEMPLATES` zero; every skill/prompt/script reference exists; trinity routing parity |

### 10.8 Failure-injection tests (V-INIT-FAIL-*)

| ID | Failure | Setup | Pass | Fail |
|---|---|---|---|---|
| V-INIT-FAIL-01 | Missing pack skill mid-run | Doctor `$PACK/project-template/skills/` | S4 fails; exit 24; diagnostic names missing skill | Silent pass |
| V-INIT-FAIL-02 | Stale `PROMPT-TEMPLATES` reference in pack | Doctor a pack template | Blast-radius sweep fails at S6 or S10; exit 31; diagnostic names file+line | Silent pass |
| V-INIT-FAIL-03 | Trinity routing divergence | Doctor `project-template/GEMINI.md` routing | Blast-radius trinity-parity check fails; exit 31 | Silent pass |
| V-INIT-FAIL-04 | Script collision | Project has own `scripts/bootstrap.sh` different from pack | S5 reports collision under [SKIP]; pack script skipped | Pack script silently overwrites |

### 10.9 PM chat workflow tests (V-PM5-*)

Scripted scenarios against a fresh v10.0 project.

| ID | Scenario | Setup | Action | Pass | Fail |
|---|---|---|---|---|---|
| V-PM5-01 | Custom agent creation — describe path (AD-4 path 1) | Fresh v10.0; developer asks for `x-deployer` | Procedure 5.1 through G-commit | 7 artifacts created (3 agent files + prompt + PLATFORM-SKILLS row + 3 trinity rows); Check 6/7/8 pass; `.codex/config.toml` untouched; single commit `feat: vN — add custom agent x-deployer` | Any artifact missing; config.toml modified; multiple commits |
| V-PM5-02 | Custom skill creation (Procedure 5.2) | Developer asks for `x-brokerage-api` skill | Procedure 5.2 | 3 SKILL.md files byte-identical frontmatter/body; PLATFORM-SKILLS.md row correct; single commit | Drift; missing row |
| V-PM5-03 | One-tool-seed path (AD-4 path 2) | Developer provides Claude `.md` | Procedure 5.1 path 2 | Two derived files created; names match; commit succeeds | Derivation drift |
| V-PM5-04 | Existing-file adoption (AD-4 path 3) | Developer provides non-convention file | Procedure 5.1 path 3 | File normalized to pack conventions; full registration committed | Rewrite diverges |
| V-PM5-05 | Improperly-added detection | Developer drops `.claude/agents/weirdagent.md` (no `x-`, not in roster) | pm-startup scan | Classified Improperly added; PM chat surfaces; developer chooses Adopt → 5.4 routes to 5.3; renamed to `x-weirdagent.md`; full registration | Missed detection |
| V-PM5-06 | Unregistered detection | Developer drops only `.claude/agents/x-deployer.md` | pm-startup scan | Classified Unregistered; missing artifacts enumerated per §5.9; Procedure 5.3 completes | False classification |
| V-PM5-07 | Defer workflow | As V-PM5-06, developer chooses Defer | PM chat flags and continues; next pm-startup re-flags | Flag persists across sessions | Flag disappears |
| V-PM5-08 | config.toml non-edit | V-PM5-01 completed | Inspect `.codex/config.toml` | Byte-identical to pack template; no `[agents.*]` added | Any edit |
| V-PM5-09 | Roster drift detection | Hand-edit PM-CHAT.md roster with non-existent agent | validate-pack.py Check 7 | Fails | Silent pass |
| V-PM5-10 | Phase-gate detection | Drop an `x-` file between sessions; trigger phase gate | Procedure 1 step 5a runs scan | Surfaces new file; pauses before prompt generation | Phase proceeds silently |

### 10.10 Prompt migration correctness (V-PROMPT-*)

| ID | Check | Setup | Action | Pass | Fail |
|---|---|---|---|---|---|
| V-PROMPT-01 | Before/after token count | v9.3 monolith (~6,482) vs. v10 per-agent sum | `wc -w` × 1.3 on both | Sum matches within ±5% (accounts for hoisted Prompt Authoring Principles) | Drift > 5%; content loss |
| V-PROMPT-02 | Every v9.3 Template 1–14 accounted for | v9.3 PROMPT-TEMPLATES.md vs. `docs/pack/prompts/` | Line-by-line check using Part 4 §4.1 destination map | Every template's content in mapped file under mapped slug; T10–12 supersession note present in auditor.md | Content missing |
| V-PROMPT-03 | v9.x incremental additions carried forward | v9.3 baseline | Manual check | T1 BD-038 active-skills instruction in `pm-chat.md ## Variant: kickoff`; T8 STATUS.md phase-title rule in `## Variant: backlog-status-update`; BD-043 Gemini refs preserved throughout | Any addition lost |
| V-PROMPT-04 | No corruption | v10 pack prompts | Each file passes Check 6 | All 10 files + PROMPT-AUTHORING.md pass | Any failure |
| V-PROMPT-05 | Custom prompt format parity | PM-chat-created `x-deployer.md` (Part 5 §5.1 worked example) | Check 6 | `x-` file passes identical format check | Fails on `x-` file |

### 10.11 `x-` file preservation (V-X-PRESERVE-*)

| ID | Setup | Action | Pass | Fail |
|---|---|---|---|---|
| V-X-PRESERVE-01 | v9.3 fixture with 3 `x-` agent files, 3 `x-` skill dirs | Migration | All 6 `x-` artifacts byte-identical; `docs/pack/prompts/` populated with 10 pack prompts + PROMPT-AUTHORING.md; no spurious `x-` prompt | Any byte change |
| V-X-PRESERVE-02 | Synthetic v10.x fixture with `x-` prompt | Upgrade to later v10.y | `x-` prompt preserved byte-identical | Change |
| V-X-PRESERVE-03 | Stray `x-` file inside pack skill dir | Migration | Pre-flight stops per Part 6 §6.1 row 3; developer guidance printed; no write | Silent pass or partial write |

### 10.12 BD-045 content review (V-BD045-*)

| ID | Scope | Action | Pass | Fail |
|---|---|---|---|---|
| V-BD045-01 | Trinity diff — Capabilities section | `diff` across three trinity files | Byte-identical | Any divergence |
| V-BD045-02 | Trinity diff — anti-pattern bullet | `diff` across three files | Byte-identical | Any divergence |
| V-BD045-03 | Language-agnostic trinity wording | Read trinity `## Capabilities pattern` and bullet | No language-specific syntax (no `OptionSet`, no `Protocol`, no `isinstance`) | Any language-specific example |
| V-BD045-04 | Per-language skill coverage | Read apple-architecture-core 11–14, python-best-practices 14–17, architecture-review 14–17 | Each set names both forms with idiomatic examples; each names where capability validation belongs | Missing form; missing placement rule |
| V-BD045-05 | Auditor-architecture trio symmetry | `diff` across three auditor files | Claude & Gemini markdown byte-identical; Codex plain-bullet semantically identical to Part 3 §3.7 | Semantic divergence |
| V-BD045-06 | LSP-vs-capabilities statement | Read every location where relationship stated (Part 3 §3.9) | Each uses BD-045 formulation verbatim or closely paraphrased; never softens to "escape hatch" | Misstatement |
| V-BD045-07 | Renumbering integrity | Grep for rule-number references across the three modified skills and any referrer | Every rule reference points at intended content post-renumber | Stale reference |

### 10.13 Blast-radius sweep (V-BLAST-*)

From Part 7 §7.7. Each row is a testable assertion with expected result
on a correctly-installed v10 pack.

| ID | Sweep | Expected | Failing |
|---|---|---|---|
| V-BLAST-01 | `grep -r PROMPT-TEMPLATES` across `.claude/ .codex/ .gemini/ docs/pack/ CLAUDE.md AGENTS.md GEMINI.md agent-run.sh scripts/` | Zero matches | Any hit |
| V-BLAST-02 | Placeholder baseline (diagnostic) | Baseline recorded | Baseline regression only |
| V-BLAST-03 | Every skill in PLATFORM-SKILLS.md present in all three skill dirs | All present | Any missing |
| V-BLAST-04 | Every prompt file referenced from PM-CHAT.md / trinity exists in `docs/pack/prompts/` | All present | Any missing |
| V-BLAST-05 | Every script in trinity Scripts tables exists in `scripts/` after conditional removal | All present | Any missing |
| V-BLAST-06 | Trinity routing-table agent-set parity | Three sets identical | Divergence |

### 10.14 Incremental testability contract (V-INC-*)

Each migration stage leaves the project in a testable state (Part 6
§6.8).

| ID | Stage | Test |
|---|---|---|
| V-INC-01 | After S0 | `git status` shows only `.pack-migration-backup/` untracked |
| V-INC-02 | After S1 | `./agent-run.sh --help`; each pack agent invocation on trivial task succeeds |
| V-INC-03 | After S2 | Skills visible (Claude live detection; Gemini `/skills reload`; Codex next session) |
| V-INC-04 | After S3 | `./scripts/bootstrap.sh` runs; `./scripts/validate.sh` runs |
| V-INC-05 | After S4 | `docs/pack/prompts/` exists; Check 6 passes on all 10 files + PROMPT-AUTHORING.md |
| V-INC-06 | After S5 | Trinity-rule CI check passes locally; `git diff` shows only pack-owned region changes |
| V-INC-07 | After S6 | Report shows `customization: none` or `divergence detected`; backup exists |
| V-INC-08 | After S7 | Report file written with every required section |
| V-INC-09 | Resumability | Kill mid-stage; re-invoke; verify it reads sentinels and resumes |

### 10.15 Verification plan maintenance rule (V9 Lesson 4)

> **If any v10 design decision is reversed in a v10.x patch, update
> this verification plan in the same commit, not only the operational
> docs.**

Concretely: any commit modifying V10-DESIGN.md, METHODOLOGY.md Procedure
5 / 5-R, migrate-v9-to-v10.sh, init-project.sh, the format rules in
Part 4 §4.5, or the preservation rules in Part 6 §6.6 must also update
the corresponding V-* tests in this Part 10 in the same commit. Pack CI
includes a soft-check (not hard-fail) that flags commits touching those
files without a matching edit to Part 10.

### 10.16 Coverage summary — Part 9 cells → Part 10 tests

| Part 10 test group | Part 9 cells covered |
|---|---|
| V-M1-* | 16 CP M1 cells |
| V-INIT-NEW-* | 5 CP M2 cells |
| V-INIT-EXIST-* | 7 CP M3 cells |
| V-PM5-* | Custom-agent-creation outcome across four PM chat tools |
| V-BD045-* | Non-matrix BD-045 content coverage |
| V-PROMPT-* | Non-matrix prompt-migration coverage |
| V-X-PRESERVE-* | Custom-file-state × M1 coverage |
| V-M1-ROLLBACK | Rollback design requirement |
| V-CI-* | validate-pack.py + workflow |
| V-INIT-VERIFY-*, V-INIT-FAIL-* | Part 7 §7.7 inline verification |
| V-INC-* | Part 6 §6.8 incremental testability |
| V-BLAST-* | Part 7 §7.7 blast-radius sweep |

Every Part 9 CP cell maps to at least one Part 10 test.

---

## Part 11 — V9 Lessons Carried Forward

Explicit map from V10-PREDESIGN Part 8 lessons to the V10 design
sections that apply them.

### L1 — Skills distribution design changed twice

*Setup / decision changes must have explicit upfront justification for
where the operation lives.*

Applied in:
- **Part 4 §4.1 token budget rationale, §4.7 pm-startup decision.** Each
  operation's placement named with rationale (pm-startup does not read
  prompts; operation belongs at generation time).
- **Part 6 §6.1, §6.8, §10.1 operation-placement tables.** Every
  migration operation's lifecycle stage is justified (detection in PM
  chat vs. script; reconciliation in PM chat; merge splice in Python
  helpers; etc.).
- **Part 7 §7.2 shared library decision and §7.8 skill-gap logging
  placement.** Each init-project operation placed at one lifecycle
  stage; skill-gap logging lives in the PM chat because shell has no
  project context.
- **Part 2 AD-3 single-path rationale for custom-file creation.** Two
  documented paths (chat-driven and manual procedure) rejected
  explicitly as the L1 pattern.

### L2 — Gemini CLI misunderstanding

*Tool-specific behavior must be verified against actual tool
documentation before being committed to in design.*

Applied in:
- **Step 2 of the V10-DESIGN-PROCESS-PLAN.** CLI verification pass ran
  before any design decision dependent on CLI behavior.
- **Part 5 §5.4** (OQ-2 resolution). No per-agent `config.toml` entry
  required — reverses V10-PREDESIGN assumption based on Step 2 Fact 1 +
  Contradiction C-1. Touch-point rows removed.
- **Part 5 §5.8** (detection workflow). Runs at PM-chat layer, not
  tool-emitted hook, because Codex emits no file-edit hook (Step 2
  Contradiction C-3), Claude Code has them, Gemini's hooks not
  deeply verified. Three asymmetric enforcement layers rejected.
- **Part 2 AD-1 Codex hyphen rule.** Codex `name = "x-<name>"` accepted
  per Step 2 smoke test resolving Contradiction C-2.
- **Part 2 AD-1** (Codex hyphen rule from Step 2 smoke test), **Part 5
  §5.4** (OQ-2 per Step 2 C-1), **Part 5 §5.8** (detection at PM-chat
  layer per Step 2 C-3). All CLI-adjacent claims cite Step 2 facts.

### L3 — GEMINI.md trinity violation

*Trinity rule must be validated against each tool's actual file system
conventions, not extrapolated.*

Applied in:
- **Part 3 §3.2, §3.7, §3.8.** BD-045 content has identical wording
  across CLAUDE.md / AGENTS.md / GEMINI.md and across the three
  auditor-architecture files (Codex formatting deviation justified
  explicitly).
- **Part 5 §5.1, §5.6, §5.10, §5.11.** Each tool's custom-agent file
  format specified on its own terms (Claude YAML+md, Codex TOML with
  `developer_instructions`, Gemini YAML+md). PM-CHAT.md is not in the
  trinity (single-file operational doc) — asymmetry justified.
- **Part 6 §6.6.** Trinity splice logic runs on all three trinity files
  atomically in stage S5; partial trinity update is caught by migration
  assertion.
- **Part 8 §8.5.** Trinity-rule integrity audit across all v10 BD edits.

### L4 — V9-DESIGN.md verification checklist became stale

*When a design decision is reversed, update the original design record's
verification checklist, not only the operational docs.*

Applied in:
- **Part 4 §4.8 stale-reference inventory.** Every PROMPT-TEMPLATES.md
  reference inventoried with update obligation.
- **Part 6 §6.7 maintainer note in MIGRATION guide.** Explicit
  instruction that v10.x reversals update the guide.
- **Part 10 §10.15.** Verification plan maintenance rule — future v10.x
  commits reversing a v10.0 decision must update Part 10 tests in the
  same commit.
- **V10-PREDESIGN.md supersession banner** (Step 13). Annotated, not
  silently mutated.
- **V9-DESIGN.md annotation (Part 8 row 36).** v10 supersession notes
  next to references to PROMPT-TEMPLATES.md as a shipping artifact;
  historical content not rewritten.

### L5 — Maintenance-docs stale references missed in audits

*Every doc audit must include maintenance-docs, not just operational
docs.*

Applied in:
- **Part 4 §4.8 must-update list** explicitly partitions into operational
  (must update) and annotate-only (historical). `maintenance-docs/`
  files receive annotation obligations.
- **Part 8 §8.2.2 annotation rows (36, 37).** V9-DESIGN.md and
  V9-AUDIT-REPORT.md get supersession notes.
- **Part 10 §10.13 V-BLAST-01.** Sweep includes `maintenance-docs/` grep
  targets in the blast-radius-wider-than-change-set contract.
- **Step 12 of the V10-DESIGN-PROCESS-PLAN** — pack-reviewer audit scope
  includes maintenance-docs.

---

## Part 12 — Implementation Sequence Outline

Per AD-10 and V10-DESIGN-PROCESS-PLAN Step 1 G1 resolution: **BD-045 →
BD-046 → BD-044.**

This part is intentionally thin. Phase 3 (implementation planning)
produces the detailed per-file edit sequence and per-commit plan. This
part names only the top-level ordering and cross-BD coordination
points.

### 12.1 Order

1. **BD-045 — Capabilities pattern.** Most independent of the three —
   adds content to existing files without restructuring. Lowest risk;
   no dependency on BD-046 or BD-044.
2. **BD-046 — Custom agent/skill support + prompt reorg + migration.**
   Most structural — creates new directories (`docs/pack/prompts/`),
   moves content out of the monolith, adds custom-agent mechanism,
   ships the migration script. Defines the v10 file structure that
   BD-044 consumes.
3. **BD-044 — init-project.sh + QUICKSTART router.** Depends on the
   final v10 file structure; init-project.sh must know what it copies
   from `docs/pack/prompts/` and must not create `x-` files.

Within BD-046, the internal order is: prompt reorg (Part 4) → custom-
agent mechanism (Part 5) → migration script and guide (Part 6). Each
stage leaves the pack in a working state per incremental testability.

### 12.2 Cross-BD coordination points

- **Trinity files** get three independent edits across BD-045 and
  BD-046: the `## Capabilities pattern` section (BD-045); the
  Document-locations table `docs/pack/` row (BD-046 prompt reorg); the
  `### Custom agents` sub-section at end of Phase routing (BD-046
  custom-agent). These three edits go in a single commit per trinity
  file in the BD-046 stage, so the trinity rule is never half-present.
  BD-045 commits its content first (row 1/2/3 of Part 8); BD-046 layers
  its edits into the same files in the BD-046 commit batch.
- **METHODOLOGY.md** gets Procedure 5 (Part 5 §5.7) and Procedure 5-R
  (Part 6 §6.5) additions plus the PROMPT-TEMPLATES.md stale-reference
  sweep — all in one commit (Part 8 rows 30/43/48).
- **QUICKSTART.md** is rewritten as the three-path router in BD-044;
  the same commit drops PROMPT-TEMPLATES.md references (Part 8 row
  31/54).
- **README.md** Repository Layout updates land in BD-044 (Part 7 §7.12
  authoritative convention note + new files list); the v10.0 version-
  table row lands at v10.0 ship.
- **validate-pack.py** checks 6/7/8 land in the BD-046 batch (Part 8
  rows 56–58); Check 9 lands in the BD-044 batch (row 59); Check 1
  sanity after BD-045 renumbering is verified in the BD-045 batch
  (row 60).

### 12.3 Commit format

Per CLAUDE.md (pack repo):
- `feat: v10 — BD-NNN short description` for BD-scope commits.
- `docs: v10 — BD-NNN short description` for documentation-only commits.
- `fix: brief description` for corrections.
- Version prefix is `v10` from the first v10 commit onward (the design
  phase itself uses `v9` prefix because v10 has not shipped yet, per
  V10-DESIGN-PROCESS-PLAN §4).

### 12.4 Ship boundary

v10.0 ships when:
- All BD-045, BD-046, BD-044 commits on `v10-dev` branch.
- All Part 10 critical-path tests passing (Phase 4 audit).
- `Validate Pack` CI passing.
- CHANGELOG.md v10.0 entry and README.md v10.0 version-table row in
  place.
- Merge to main; tag `v10.0`; floating `v10` tag created.

v10.1+ follows the minor-version procedure documented in CLAUDE.md —
floating `v10` tag moves to the latest minor.

---

## Part 13 — Open Items Deferred

Every V10-PREDESIGN OQ is resolved in Parts 3–10 with one exception; the
Phase 3 back-reference item from Part 3 §3.10 is also surfaced here.
All Step 2 CLI follow-up items not blocking v10 design are recorded.

### 13.1 Deferred — Codex skill loading with `x-` prefix (Step 2 follow-up 3)

*Resolution target: Phase 4 BD-046 pre-merge verification.*

Step 2 Fact 2 (Claude Code live detection) and Fact 3 (Gemini
progressive disclosure + `/skills reload`) confirmed feasibility of
custom `x-` skills for two of three tools. Codex skill loading
(`https://developers.openai.com/codex/skills`) was not fetched during
Step 2 and TOOL-COMPARISON.md's note "Codex skills require
`--enable skills` flag" is unverified.

**Fallback:** Part 5 §5.1 documents the expectation that Codex custom
skills load consistently with the other two tools; Phase 4 runs a
smoke-test before BD-046 merge. If Codex rejects the `x-` prefix on
skills specifically, Part 5 §5.1 row 4 gains a tool-specific footnote
and Procedure 5.2 handles it.

No design decision in this document is blocked by this verification.

### 13.2 Deferred — Gemini CLI Hooks verification (Step 2 follow-up 2)

*Resolution target: only if a future v10.x design depends on Gemini
hooks.*

Step 2 did not deeply inspect Gemini CLI Hooks
(`https://geminicli.com/docs/cli/hooks`). v10 design does not depend on
any hook mechanism (detection runs at PM-chat layer per Part 5 §5.8), so
no verification is needed for v10.0. Recorded here so a future minor
can do the verification before building on Gemini hooks.

### 13.3 Deferred — Claude Code `.claude/agents/*.md` live reload confirmation (Step 2 follow-up 4)

*Resolution target: before BD-046 GA or at Phase 4 smoke test.*

Step 2 Fact 2 §1 confirmed live change detection for Claude Code
skills. Whether `.claude/agents/*.md` live-reload works the same way
(adds/edits picked up without restart) was not explicitly confirmed on
the skills docs page. Part 5 §5.8 assumes it does; Phase 4 smoke test
at first BD-046 merge validates.

**Fallback:** if restart is required, Part 5 §5.8 detection workflow
still works (session-local detection signals don't drive the scan
anyway); only the user-facing message changes to note "restart Claude
Code after PM chat creates the agent."

### 13.4 Deferred — audit-methodology/SKILL.md rule 15 back-reference (Part 3 §3.10 handoff)

*Resolution target: Phase 3 implementation planning.*

Part 3 §3.7 auditor-architecture edits add a `Capabilities pattern
adherence` scope bullet whose authority (`per audit-methodology rule 15`)
is inherited from v9.x. Whether rule 15 in
`audit-methodology/SKILL.md` needs a matching "capabilities" extension
is a Phase 3 surfacing item. It is not a BD-045 location requirement
(BD-045 lists exactly nine locations; audit-methodology is not one).

**Fallback:** if Phase 3 decides yes, add a row to the Part 8 touch-
point inventory during Phase 3 planning — a single-file edit in
`project-template/skills/audit-methodology/SKILL.md`.

### 13.5 Not deferred — everything else

Every other CD and OQ from V10-PREDESIGN is resolved in this document:

- CD-1 → AD-1
- CD-2 → AD-2
- CD-3 + OQ-7 → AD-3
- CD-4 → AD-4 + Part 5 §5.1
- CD-5 → AD-5 + Part 6 §6.1
- CD-6 → AD-6 + Part 5 §5.1
- CD-7 → AD-7 + Part 5 §5.2
- CD-8 → AD-8 + Part 4
- CD-9 → AD-9 + Part 5 §5.1 row 4, §5.2
- CD-10 → AD-10 + Part 7
- CD-11 → AD-11 + Part 3
- CD-12 → AD-12 + Part 6
- CD-13 → AD-13 + Part 6 §6.2
- OQ-1 → Part 5 §5.3
- OQ-2 → Part 5 §5.4
- OQ-3 → Part 6 §6.4
- OQ-4 → Part 4 §4.7
- OQ-5 → Part 7 §7.1
- OQ-6 → V10-DESIGN-PROCESS-PLAN.md (design process)
- OQ-7 → AD-3 + Part 5 §5.8
- OQ-8 → Part 5 §5.5
- OQ-9 → Part 4 §4.4
- OQ-10 → Part 12
- OQ-11 → Part 4 §4.5
- OQ-12 → Part 7 §7.3
- OQ-13 → Part 3 (concrete drafts for all nine locations)
- OQ-14 → Part 10

---

## Appendix A — Design Requirement to Section Cross-Reference

Every Design Requirement in V10-PREDESIGN.md Part 7 is addressed by at
least one V10-DESIGN.md section.

| Design Requirement | V10-DESIGN sections |
|---|---|
| **Automated and manual workflows** | Part 5 §5.1 (PM chat creation workflow + escape hatch); Part 7 §7.6 (init-project.sh + developer preview/confirm); Part 6 §6.9 (migration automated option + manual guide) |
| **Resource considerations** | Part 4 §4.1 (token budget analysis); Part 5 §5.8 (detection scan cost is negligible — ~170 directory entries, pure string matching) |
| **Maintenance considerations** | Part 5 §5.3 (single source of truth for pack roster); Part 6 §6.6 (positional splice rules preserve project-owned regions on upgrade); Part 8 (touch-point inventory as the maintenance contract); Part 7 §7.13 (no hardcoded file lists in init-project.sh) |
| **Document access patterns** | Part 4 §4.7 (prompts read on-demand at generation time, not startup); Part 5 §5.10 (PM-CHAT.md file-access table updates); Part 7 §7.9 (QUICKSTART.md as router, not procedure) |
| **Best use of RAG** | Part 4 §4.1 RAG analysis (monolith RAG dropped; per-agent direct read on most surfaces; filesystem MCP recommended for Claude Desktop); Part 6 §6.9 (automatable prompt works on all four surfaces) |
| **PM chat tool flexibility** | Part 5 §5.1 (workflow on all four PM chat surfaces); Part 6 §6.9 (migration works on CLI and Desktop with MCP); Part 7 §7.8 (init-project.sh end-of-run prompt works on all four surfaces); Part 9 §9.6 (matrix has CP cell per PM chat tool); Part 1 §v9.x compatibility (preserved capabilities list) |
| **Seamless BD integration** | Part 3 §3.10, Part 5 §5.13, Part 6 §6.11, Part 7 §7.13 (each BD's section explicitly references the other BDs' outputs); Part 8 §8.4 cross-BD coordination rows |
| **Rollback plan** | Part 6 §6.7 (backup directory; restore sequence; guarantees); Part 10 §10.3 V-M1-ROLLBACK rehearsal |
| **Incremental testability** | Part 6 §6.8 (eight migration stages S0–S7 with post-stage assertions and sentinel files); Part 7 §7.6 (eleven init-project.sh stages S0–S10 with per-stage checks); Part 10 §10.14 V-INC-* |
| **Inline verification at every stage of every process** | Part 6 §6.8 (migration); Part 7 §7.7 (init-project.sh stage-local + blast-radius); Part 5 §5.8 (detection scan); Part 10 §10.7–§10.8 V-INIT-VERIFY-* / V-INIT-FAIL-* / V-BLAST-* (testable assertions for every verification stage) |

---

## Appendix B — Glossary

| Term | Definition |
|---|---|
| **Pack** | The DHS AI Agent Config Pack repository (`dhs-ai-agent-config-pack`). |
| **Project** | A repository that has installed the pack. |
| **Trinity files** | `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` — three tool-context files that the trinity rule keeps symmetric. |
| **Trinity rule** | Edits to one trinity file require parallel edits in the other two unless asymmetry is justified by tool-specific behavior. |
| **Pack roster** | Hardcoded list of canonical v10 pack agent stems in `project-template/docs/pack/PM-CHAT.md` `## Pack agent roster`. |
| **`x-` prefix** | The reserved filename prefix for project customizations (custom agents, custom skills, custom prompts). The pack never ships `x-` files. |
| **PM chat** | The LLM chat the developer drives for a project (Claude Code CLI, Claude Desktop, Codex CLI, or Gemini CLI). |
| **Pack chat** | The LLM chat that operates on the pack repo itself (usually CLI). Distinct from PM chat. |
| **AD-N** | Approved Decision N in Part 2. |
| **CD-N** | Candidate Decision N from V10-PREDESIGN Part 2 (now superseded by AD-N). |
| **OQ-N** | Open Question N from V10-PREDESIGN Part 3 (now resolved or deferred in Part 13). |
| **Seven detection directories** | `.claude/agents/`, `.codex/agents/`, `.gemini/agents/`, `.claude/skills/*/`, `.codex/skills/*/`, `.gemini/skills/*/`, `docs/pack/prompts/`. See AD-10 §Detection directories and Part 5 §5.8. |
| **Detection scan** | PM-chat-layer scan of the seven directories at pm-startup and phase gate; classifies files as Pack / Registered custom / Unregistered custom / Improperly added. Part 5 §5.8. |
| **Procedure 5** | METHODOLOGY.md Part 7 procedure for creating custom agents and skills, detecting manual additions, and adopting them. Part 5 §5.7. |
| **Procedure 5-R** | METHODOLOGY.md reconciliation procedure for `_v9-backup.md` from a diverged v9.3 PROMPT-TEMPLATES.md. Part 6 §6.5. |
| **Stage sentinel** | Migration-stage completion marker (`.pack-migration-backup/v9.3-to-v10.0/stage-S<N>.done`). Enables resumability. |
| **Blast-radius sweep** | Verification sweep wider than the immediate change set; catches stale references in files that were not directly edited. Part 7 §7.7, Part 10 §10.13. |
| **Agent report file convention** | Convention requiring every agent prompt to include a `REPORT FILE:` path and read-only or write-capable framing. Part 4 §4.6. |

---

*End of V10-DESIGN.md.*

*Status: DRAFT — PENDING REVIEW. Approval record to be added at Step 13
of V10-DESIGN-PROCESS-PLAN.md.*
