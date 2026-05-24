---
agent: pm-chat
variants:
  - kickoff
  - backlog-status-update
  - generate-setup
  - generate-agent-kickoff
---

# pm-chat — PM chat templates

The `agent:` value `pm-chat` is reserved. The PM chat is the consumer
of these templates, not an agent. Each variant is a prompt the PM chat
either receives (kickoff, pasted by the developer) or composes and
uses on itself (backlog-status-update, generate-setup,
generate-agent-kickoff).

## Variant: kickoff

*Paste this at the start of a new PM chat session to establish project context.*
*Fill in all [PLACEHOLDERS] before pasting.*

**Convention exception:** kickoff is a context handoff, not an agent-task prompt. The labeled-section convention does not apply. All other variants and all other prompt files in this directory follow it.

**Before pasting:**
- If you are running Gemini CLI and currently in plan mode (`/plan`), exit plan mode before continuing — kickoff requires shell execution.
- If you are pasting this into Claude Web or ChatGPT Web without shell access, reply `manual` when asked below.
- Shell-capable surfaces run kickoff auto-discovery (INSTALL-PROCEDURES.md Procedure 7); non-shell surfaces use the manual-fallback prose under the `manual` branch of this prompt (see "Next, based on your surface declaration" below).

I am starting a new Claude Chat session for **[PROJECT_NAME]**.

**Project:** [2-3 sentence description of what the project is and does]
**Platform:** [e.g., macOS 15+, Xcode 26.3, Swift 6 / Python 3.12+]
**Current phase:** Phase [N] — [Phase title] ([not started / in progress])
**Pack version:** AI Agent Config Pack v10

**Key architectural decisions already made:**
- [Architecture pattern, e.g., MVVM with layered domain/data/presentation]
- [Key protocol decisions, e.g., DataStore protocol over SwiftData]
- [Any other settled decisions]

**Before I do anything else:** I will declare my surface and pause
for your reply before running any non-read-only action. The recognized
surfaces are Claude Code CLI, Codex CLI, Gemini CLI, or Claude Desktop
with Desktop Commander (shell-capable — I typically declare `shell`
by inference); and Claude Web or ChatGPT Web (no shell — I declare
`manual` and route to the manual fallback). Reply `yes` to authorize
Form R discovery, `manual` to override mid-kickoff, or per the
INSTALL-PROCEDURES.md § 7.5 reply grammar (`no` / `skip` / `abort` / `edit`).

**Project documents the PM chat needs in context:** ARCHITECTURE.md,
IMPLEMENTATION-PLAN.md (current phase), STATUS entries, BACKLOG
entries. Resolve the location of STATUS and BACKLOG entries via the
trinity `## Document locations` table (the Source column says `flat`
in flat-file mode; `mixed` in tracker mode means BACKLOG/STATUS are
read-only mirrors of the tracker — read them via the tracker on
shell-capable surfaces with `gh` configured, or via the flat-file
mirror otherwise). Locate and read these by whatever means your
surface provides — local repo read on shell-capable surfaces;
project-knowledge or GitHub-connector search on Web with a Project +
connector; equivalent retrieval on other surfaces. If you cannot
access them, report what you can reach and I will adapt.

**Your role as PM chat:**
- Generate agent prompts for each phase (coder, reviewer, tester, docs-researcher)
- Analyze reviewer output and categorize findings
- Make architectural and planning decisions
- Never write code or make large file changes directly
- For small doc updates (STATUS.md, BACKLOG.md): use Desktop Commander if available,
  otherwise output content and git commands for me to run

Confirm you can see the project documents, then tell me the current state and what
we should do next.

If `PM-CHAT.md` exists in the project root with `[PROJECT_NAME]` still as a
placeholder, fill it in now: replace `[PROJECT_NAME]` with the actual project name,
update the "Additional project documents" section if needed, remove the template
comment block at the top, and commit it. This only needs to be done once.

If the **Active skills** line in the Skill loading section of `CLAUDE.md` still
contains placeholder text, populate it now: read `PLATFORM-SKILLS.md`, determine
the skill set for this project's type, and write the list. Apply the same line
to `AGENTS.md` and `GEMINI.md`. Commit.

---

**Next, based on your surface declaration:**

On `shell`: I will read `docs/pack/INSTALL-PROCEDURES.md` Procedure 7
directly (not via RAG — Procedure 7 is order-sensitive) and follow
its gates G7-discovery / G7-install / G7-edit / G7-machine before
any write or install.

On `manual`: Procedure 7 is shell-only (see Procedure 7 § 7.0) and
is not entered on non-shell surfaces. I will instead walk you
through the manual-fallback equivalents in-chat. You run the
commands locally and report values back to me; I will compose the
corresponding file edits for you to paste. The manual-fallback
covers the same four sub-flows Procedure 7 automates:

- **M.A — (Apple only) Xcode scheme variables.** Run
  `xcodebuild -list` and `xcrun simctl list devices available`
  locally and report the chosen scheme name + a destination string
  (e.g., `platform=iOS Simulator,name=iPhone 16,OS=latest` or
  `platform=macOS`). I will compose the corresponding edits to
  `scripts/validate-swift.sh`, `scripts/test-swift.sh`, the
  `env` block of your CLI's settings file (the trinity
  `## Document locations` table names the per-CLI path), and —
  only if your project uses an Xcode-generated source layout (e.g.,
  `MyApp/` and `MyAppTests/` rather than SPM's `Sources/` and
  `Tests/`) — `SWIFT_SOURCE_DIRS` in `scripts/format-swift.sh`.

- **M.B — (Apple only) Install swift-format.** Run
  `brew install swift-format` locally. `scripts/format.sh` warns
  and exits 0 if swift-format is not installed, so this is not
  blocking, but you want it for local formatting.

- **M.C — (gRPC only) Set up proto code generation.** Run
  `brew install bufbuild/buf/buf`, `brew install swift-protobuf`,
  `brew install grpc-swift` for the Apple side; for the Python
  side, `uv add grpcio-tools grpcio grpcio-status grpcio-reflection`.
  Then replace the example service at
  `proto/example/v1/example_service.proto` with your own and run
  `./scripts/proto-gen.sh`.

- **M.D — (Apple only) Install Xcode companion files (machine-level,
  once per Mac).** Create the target directories and copy the four
  files from the pack's `xcode-companion-templates/` directory into
  `~/Library/Developer/Xcode/CodingAssistant/`. The two
  sub-directories are `ClaudeAgentConfig/` (CLAUDE.md + settings.json)
  and `codex/` (AGENTS.md + config.toml). Report `done` once the
  copy completes; replace any older companion files if previously
  installed.

After you report the values + completion of M.A–M.D, I will compose
the corresponding edits and paste them back for you to apply.

## Variant: backlog-status-update

*PM chat only — requires explicit user approval before executing. Do not use this
template to make changes the user has not reviewed and approved.*

**Context:** A BACKLOG and/or STATUS state-change requires recording. The
PM chat composes this prompt against itself after explicit user approval.

**Required reading:** `BACKLOG` and/or `STATUS` entries in full,
depending on which is targeted (resolve location via the trinity
`## Document locations` table; in flat-file mode read the named
files; in tracker mode read the tracker entries — the mirror is
regenerated by the chat after every write).

**Problem:** A BACKLOG/STATUS state-change is required (new entry, status
flip, resolution, phase advance, etc.) and has been approved by the user.

**Goal:** The named entries are updated per the schema below. No other
files touched.

**Success criteria:**
- Exact entries exist with the prescribed BACKLOG-entry shape (per the
  schema block under Constraints).
- Phase-title links in STATUS.md validate (anchor format per the rule
  under Constraints).
- Cancelled/Deprecated items have flag-for-review applied to dependents.
- Artifact (BACKLOG.md and/or STATUS.md edits) is the target file edit
  itself; no separate report file is needed (sub-case B).

**Files in scope:** `BACKLOG.md` and/or `STATUS.md` only. No other file
is modified.

**Constraints:** PM chat self-prompt. Requires explicit user approval
before executing. Do not modify any other file.

[DESCRIBE EXACT CHANGE — e.g.:]

**To add a new BACKLOG item:**
Add the following entry to BACKLOG.md:

```
**TD-[NNN] — [Short title]**
Type: TODO(scope) | KNOWN GAP(critical|functional|polish) | VERIFY(source)
Status: Open | Unblocked
Blockers:
  - [Named specific dependency — phase N, TD-NNN, or external condition]
  - [Additional blocker if any — all must resolve before item is actionable]
Unblocks: [TD-NNN, ...] or None
  ← informational only; PM chat derives actionability from Blockers, not this field
File/Symbol: `path/to/file` — `SymbolName`  ← optional; symbol name not line number; n/a if none
Description: [What the work is and why it was deferred]
Context: [What was known at deferral time — descriptive only, no proposed solution]
```

**To mark an item resolved, cancelled, or deprecated:**
Find TD-[NNN] and append the Resolution field:
```
Resolution: [date, one of: completed | cancelled | deprecated, brief note]
```
Change Status to: Resolved | Cancelled | Deprecated accordingly.
Do not delete the item or any other fields.

For Cancelled or Deprecated: after updating the item, flag all Open or Unblocked
items whose Blockers list names this TD-NNN for user review before proceeding.
Do not automatically unblock any of them.

**To update STATUS.md:**
- Mark Phase [N] as ✅ Complete in the phase table
- Update "Current Phase" to: Phase [N+1] — [Title] (not started)
- Update "Next Actions" to: [list]
- Update "Key Metrics" test count to: [N] passing, 0 failing
- Link every phase Title in the phase table to its heading in
  `IMPLEMENTATION-PLAN.md` using `[Title](IMPLEMENTATION-PLAN.md#anchor)` format.
  GitHub anchor: lowercase, spaces → hyphens, em-dash `—` removed (leaves `--`),
  special characters (backticks, colons, parentheses, periods, asterisks, slashes) stripped.
  Example: `## Phase 35 — Live Broker Sandbox Verification` →
  `[Live Broker Sandbox Verification](IMPLEMENTATION-PLAN.md#phase-35--live-broker-sandbox-verification)`.

**Completion report:** The artifact is the target-file edit itself
(sub-case B). Confirm what was changed by naming the file(s) edited
and the change summary inline in chat — no separate REPORT FILE.

## Variant: generate-setup

*PM chat self-prompt — composes a project-specific `SETUP.md` from
the planning conversation and the inlined skeleton below.*

**Context:** A new project has no `SETUP.md`. The PM chat assembles
`SETUP.md` from (a) the project-planning conversation context already
in the PM chat session, (b) the project's installed trinity
(`CLAUDE.md` / `AGENTS.md` / `GEMINI.md` at the project root, which
the PM chat composes the SETUP.md against), and (c) the inlined
skeleton below.

**Required reading:** Project-root trinity (`CLAUDE.md` /
`AGENTS.md` / `GEMINI.md`) and `docs/pack/METHODOLOGY.md` (already
installed at the client), plus the planning conversation context
already in the PM chat session.

**Problem:** The project has no `SETUP.md`.

**Goal:** A complete `SETUP.md` produced from the skeleton below,
with all relevant placeholders filled and inapplicable sections
removed.

**Success criteria:**
- Output is a single complete `SETUP.md` ready to save to the project
  root.
- All listed placeholder values (per the placeholder list below) are
  answered.
- No template-only HTML comment block remaining at the top.
- Sections that don't apply to this project are removed.

**Files in scope:** Project-root `SETUP.md` (sub-case B — target file
IS the artifact).

Fill in all placeholder values based on what we have discussed:
- Project name: [PROJECT_NAME]
- GitHub username: [GITHUB_USERNAME]
- Repo name: [REPO_NAME]
- Platform: [PLATFORM]
- Xcode version: [XCODE_VERSION]
- Template to use: [TEMPLATE_NAME]
- Architect agent: [ARCHITECT_AGENT]
- [Any other project-specific values]

**Constraints:** PM chat self-prompt. Output the complete file content;
do not partially fill or skip placeholders. Remove any sections that
don't apply to this project.

**SETUP.md skeleton (compose into this shape; the PM chat tailors
section presence and contents per project):**

1. **Title + 1-line description.** `# [PROJECT_NAME] — Project Setup
   Guide` and a single sentence stating what the project is.

2. **Prerequisites.** macOS [MACOS_VERSION]+, Xcode [XCODE_VERSION]
   (Apple projects), git configured, `gh` CLI optional, AI Agent
   Config Pack available locally. Remove items that don't apply.

3. **Create the GitHub repository.** Either `gh repo create
   [GITHUB_USERNAME]/[REPO_NAME] --private --clone` followed by
   `cd [REPO_NAME]`, or `git clone` of an existing repo.

4. *(Apple projects only)* **Create the Xcode project.** New Project
   wizard: choose [PROJECT_TYPE], Product Name [PRODUCT_NAME],
   Organization Identifier [BUNDLE_PREFIX], Interface SwiftUI,
   Language Swift, Storage [STORAGE_CHOICE], Testing [TESTING_CHOICE].
   Save to the cloned repo directory. Remove this section for
   non-Apple projects.

5. **Install the pack via `init-project.sh`.** Set `PACK=/path/to/
   pack` and run `"$PACK/scripts/init-project.sh" .`. The script
   previews every operation, asks for confirmation, copies the
   unified template + METHODOLOGY.md, handles conditional file
   removal per detected language, merges `.gitignore` entries, and
   applies chmod +x.

6. *(Apple projects only)* **Fill in Xcode scheme variables.** Open
   `scripts/validate.sh` and `scripts/test.sh` and set
   `XCODE_SCHEME=[SCHEME_NAME]` and `XCODE_DESTINATION=[DESTINATION]`
   (e.g., `platform=macOS` or `platform=iOS Simulator,name=iPhone 16,
   OS=latest`). Set the same values in the CLI's settings file `env`
   block (the trinity `## Document locations` table names the
   per-CLI path). For non-SPM source layouts, also set
   `SWIFT_SOURCE_DIRS` in `scripts/format.sh`. Find valid values via
   `xcodebuild -list` and `xcrun simctl list devices available`.

7. *(Apple projects only)* **Install machine-level Xcode companion
   files.** Create
   `~/Library/Developer/Xcode/CodingAssistant/ClaudeAgentConfig/`
   and `~/Library/Developer/Xcode/CodingAssistant/codex/`, then
   copy `CLAUDE.md` + `settings.json` and `AGENTS.md` +
   `config.toml` respectively from the pack's
   `xcode-companion-templates/` directory. Once per Mac.

8. **Customize trinity.** Open project-root `CLAUDE.md` /
   `AGENTS.md` / `GEMINI.md` and update at minimum: architecture
   pattern choice (MVVM / TCA / MV / etc.), project-specific rules,
   third-party APIs or frameworks.

9. **Run bootstrap.** `./scripts/bootstrap.sh`.

10. *(Apple projects only)* **Verify the project builds clean.**
    Open `[PRODUCT_NAME].xcodeproj` in Xcode, select scheme
    `[SCHEME_NAME]` with destination [BUILD_DESTINATION], Product →
    Build (⌘B). Zero errors, zero warnings.

11. **Initial commit.** `git add -A && git status` (verify nothing
    sensitive staged), `git commit -m "Initial project setup:
    [SUMMARY]"`, `git push origin main`.

12. **Set up the PM chat surface.** Per the project's chosen
    interaction surface (Claude Desktop project + GitHub connector,
    or Claude Code CLI, or Codex CLI, or Gemini CLI). The first
    message into a new PM chat session is the `kickoff` variant
    from `docs/pack/prompts/pm-chat.md`.

13. **What comes next.** Architecture kickoff, ARCHITECTURE.md,
    IMPLEMENTATION-PLAN.md, then Phase 1. Do not begin
    implementation until ARCHITECTURE.md is reviewed and approved.

14. *(Optional)* **Second machine setup.** `git clone`, `cd
    [REPO_NAME]`, `chmod +x agent-run.sh scripts/*.sh`,
    `./scripts/bootstrap.sh`, then repeat steps 6 and 7 on the new
    machine. Remove if the project is single-machine only.

**Completion report:** The artifact is `SETUP.md` written at the
project root (sub-case B). No separate REPORT FILE. Output the
complete SETUP.md content ready to save.

## Variant: generate-agent-kickoff

*PM chat self-prompt — composes a project-specific
`AGENT_KICKOFF.md` from the architecture-planning conversation and
the inlined skeleton below.*

**Context:** The architect kickoff session has no kickoff brief. The
PM chat assembles `AGENT_KICKOFF.md` from (a) the architecture-
planning conversation context already in the PM chat session, (b)
the project's installed trinity (`CLAUDE.md` / `AGENTS.md` /
`GEMINI.md`), and (c) the inlined skeleton below.

**Required reading:** Project-root trinity (`CLAUDE.md` /
`AGENTS.md` / `GEMINI.md`) and any active skill files referenced in
the trinity `**Active skills:**` line, plus the architecture-planning
conversation context already in the PM chat session.

**Problem:** The architect kickoff session has no `AGENT_KICKOFF.md`
brief.

**Goal:** A complete `AGENT_KICKOFF.md` produced from the skeleton
below, with project description, platform, pattern, structural
decisions, required stubs, test infrastructure, and external
resources filled in.

**Success criteria:**
- Output is a single complete `AGENT_KICKOFF.md` ready to save to the
  project root.
- All listed placeholder values (per the placeholder list below) are
  answered.
- Structural-decisions checklist enumerated (each □ item present with
  rationale slot for the architect to fill).
- CLI launch command for the architect agent included at the end.
- Sections that don't apply are removed.

**Files in scope:** Project-root `AGENT_KICKOFF.md` (sub-case B —
target file IS the artifact).

Fill in all placeholder values:
- Project description: [DESCRIPTION]
- Platform and targets: [PLATFORM]
- Architecture pattern: [PATTERN]
- External resources to read: [LIST WITH URLS]
- Key domain types: [LIST]
- Architecture constraints: [LIST — include project-specific ones]
  - Architecture decisions required (architect must evaluate each and document
    the chosen approach AND rejected alternatives with rationale before
    producing any stub code):
      □ Heterogeneous domain collections: type-erasure wrappers / exhaustive
        enums / protocol elevation — which and why
      □ Domain state change notification: coarse broadcast / typed payload
        streams / observation framework — granularity, back pressure,
        actor-hop cost at expected update frequency
      □ ViewModel-to-navigation coupling: direct navigator injection /
        route-intent stream / closure-based — what the ViewModel emits vs.
        what the View layer executes
      □ [Any other correctness-sensitive structural decisions specific to
        this project]
      □ Before recording rationale on any of the above, the architect must
        read the universal rules constraining these decisions in `CLAUDE.md`,
        `AGENTS.md`, and `GEMINI.md` (LSP / capability-pattern / layer
        discipline / shared-state documentation), plus any active skills
        listed in the trinity `**Active skills:**` line (concurrency,
        platform architecture, language-specific rules). The PM chat does
        not pre-decide these structural choices in this checklist —
        per `docs/pack/METHODOLOGY.md § Format-vs-solutions: worked
        examples`, prescribing a structural answer in an architect prompt
        anchors the agent and is forbidden.
- Required stubs to generate: [LIST]
- Test infrastructure required: [LIST OR NONE]

**Constraints:** PM chat self-prompt. Output the complete file content;
do not partially fill placeholders. The structural-decisions checklist
must be enumerated regardless of whether the planning conversation has
resolved each item — the slots themselves drive the architect's later
kickoff session. Remove sections that don't apply.

**AGENT_KICKOFF.md skeleton (compose into this shape; the PM chat
tailors section presence and contents per project):**

1. **Title + opening directive.** `# [PROJECT_NAME] — Architecture
   Phase Kickoff` and "You are the architecture specialist for
   [PROJECT_NAME]. Read `CLAUDE.md` at the repo root before doing
   anything else. It contains the project rules you must follow.
   Then read `AGENTS.md`. Then proceed with the tasks below."

2. **Project overview.** 2-3 sentence project description, then
   bullet rows for: Platform (e.g., macOS 15+, Xcode 26.3, Swift 6,
   SwiftUI); Architecture pattern (e.g., MVVM, TCA, layered with
   domain/data/presentation separation); Build targets (e.g.,
   single macOS app, iOS + macOS universal).

3. **External dependencies to read before designing.** A table of
   external APIs/frameworks/docs the architect must understand
   first, with direct URLs the agent will fetch. Columns: Resource
   / URL / Why it matters. Remove this section entirely if no
   external research is needed.

4. **Key domain types and protocols.** A table listing the core
   types the architecture must define. Columns: Type / Kind
   (Protocol / Value type / Reference type) / Description. For
   each: define it as a protocol in the domain layer, provide a
   stub concrete implementation in the data layer, ensure nothing
   in domain or presentation holds a concrete type directly.

5. **Architecture constraints.** Non-negotiable constraints the
   architecture must satisfy. Include the full structural-decisions
   checklist from the placeholder list above (Heterogeneous domain
   collections; Domain state change notification; ViewModel-to-
   navigation coupling; any project-specific correctness-sensitive
   decisions). Each □ item carries the same rationale slots and
   the same pre-decision constraint (read trinity universal rules
   + active skills first). Then enumerated rows for: Layer
   separation, Domain isolation, Protocol-first, plus any project-
   specific constraints.

6. **Required output — Part 1: ARCHITECTURE.md.** The architect
   writes `ARCHITECTURE.md` at the repo root covering: chosen
   architecture pattern (with rationale), layer map (which types
   and files live in which layer), key protocol definitions
   (interface for each domain protocol listed above), project-
   specific architecture section (e.g., data persistence strategy
   / streaming design / authentication model), known limitations
   and future migration path, dependency decisions (third-party
   packages and exit plan).

7. **Required output — Part 2: Stub hierarchy.** After
   ARCHITECTURE.md is complete, generate stub Swift (or Python)
   files. For each major type: full protocol definitions, complete
   domain model types with all fields, bare-minimum stub
   implementations (satisfies protocol, no errors, no real
   behavior). Enumerate the named stubs to generate as a checklist.

8. **Required output — Part 3: Test infrastructure.** Create test
   target(s) and foundational test infrastructure (enumerate
   named test targets and named mocks per protocol). Remove this
   section if the architecture phase is not responsible for test
   target creation.

9. **Verification.** After completing all output: run
   `./scripts/validate.sh` (or `xcodebuild build` / `swift build`
   as appropriate); confirm zero compiler errors, zero warnings;
   confirm every stub compiles cleanly; report files created and
   any open design questions or risks. Do not mark the phase
   complete if the project does not build clean.

10. **Important constraints.** Do not write production logic in
    this phase — stubs and protocols only. Do not add SPM
    dependencies unless `CLAUDE.md` specifically permits them in
    this phase. Do not modify `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`,
    or any file not listed above. If a design question requires a
    decision, stop and ask rather than assume.

**Completion report:** The artifact is `AGENT_KICKOFF.md` written at
the project root (sub-case B). No separate REPORT FILE.

Output the complete AGENT_KICKOFF.md content ready to save to the project root.
The developer will paste this directly into a CLI session with the architect agent:
`./agent-run.sh claude --agent architect` (or `codex`/`gemini` as appropriate).
