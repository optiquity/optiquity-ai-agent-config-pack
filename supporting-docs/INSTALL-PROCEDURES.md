# INSTALL-PROCEDURES.md — One-shot Install / Migration / Kickoff Procedures

This document hosts the procedures that fire **once or rarely** during a
project's lifecycle:

- **Project setup** — the initial install of the pack into a project.
- **Migration** — upgrading an existing project from one pack version to
  the next.
- **Kickoff** — first-run auto-discovery of toolchain values after a
  fresh install.
- **Reconciliation** — resolving the `*.v9-customized` sidecars produced
  by migration when project customization conflicts with pack updates.
- **Custom agents and skills** — the project-owned `x-*` workflow.

These procedures live in their own document because they fire infrequently
(most a maximum of once per project) and pollute METHODOLOGY.md with
content that is not relevant to ongoing project work. METHODOLOGY.md
retains a one-line pointer stub at the same H3 anchor for each relocated
procedure so legacy cross-references resolve.

This file is shipped to every project alongside `METHODOLOGY.md` by
`scripts/init-project.sh` and the active migrator
(`scripts/migrate-v10-to-v11.sh` in v11; the v9->v10 migrator was
retired in v11 per BD-121). The project-side canonical location is
`docs/pack/INSTALL-PROCEDURES.md`.

---

## Project file conventions in pack-controlled directories

Some pack-controlled directories may legitimately contain
project-specific files alongside pack-roster files. To keep the pack's
deletion logic safe, the pack reserves the **`x-` prefix** for any
file or directory the project adds to a pack-controlled location. Pack-
supplied files **never** begin with `x-`; project-supplied files in
these locations **must** begin with `x-`.

Locations governed by this convention:

| Location | Pack-roster files | Project-added files |
|---|---|---|
| `.claude/agents/` | `architect.md`, `coder.md`, `reviewer.md`, … (16 pack agents) | `x-<name>.md` |
| `.codex/agents/` | `architect.toml`, `coder.toml`, … | `x-<name>.toml` |
| `.gemini/agents/` | `architect.md`, `coder.md`, … | `x-<name>.md` |
| `.claude/skills/<dir>/` | `SKILL.md` (canonical pack skill) | `x-<file>` siblings inside the skill dir |
| `.codex/skills/<dir>/` | `SKILL.md` | `x-<file>` siblings |
| `.gemini/skills/<dir>/` | `SKILL.md` | `x-<file>` siblings |
| `.{tool}/skills/` (top level) | pack skill directories named per the roster | `x-<name>/` directories for project-added skills |
| `scripts/` | `bootstrap.sh`, `validate.sh`, `format.sh`, `agent-run.sh`, … | `x-<name>.sh` |
| `docs/pack/prompts/` | `coder.md`, `reviewer.md`, …, `pm-chat.md` (pack-roster) | `x-<name>.md` |

What the convention guarantees:

- **Pack-controlled deletions skip `x-*`.** Every site in the pack's
  scripts (`init-project.sh`, the active `migrate-vN-to-vM.sh`
  migrator, `add-capability.sh`) that removes files from these
  locations honors the `x-` prefix and leaves project-added files
  in place.
- **Pack-controlled overwrites skip `x-*`.** When the migration or
  init script copies a pack file into one of these directories, the
  copy targets only the pack-roster filename — never an `x-*`
  collision.
- **Pack-roster filenames never start with `x-`.** A future pack
  release will not introduce a roster file named `x-foo.md`. The
  pack reserves the prefix.

What the convention does **not** guarantee:

- The pack does not enforce naming for files outside these locations.
  Project-only directories (e.g., `docs/project/`, `tests/`, source
  trees) are off-limits to pack scripts; the `x-` convention does not
  apply there.
- The convention is a contract between the pack and the project's
  pack-controlled directories. It does not govern semantics inside
  the file (an `x-*` file can have any content the project chooses).

If a developer adds a project-specific file to a pack-controlled
location without the `x-` prefix, the next migration's detection scan
flags it as **improperly added**. Procedure 5.4 below covers
reconciliation.

---

## Procedure 5 — Custom agent and skill workflow

Projects may create project-specific agents and skills beyond what the
pack ships. All custom files use the `x-` prefix per the convention
above. Pack-supplied files never begin with `x-`.

Procedure 5 has six sub-procedures (5.1–5.6). The reconciliation
variant for migration-time customization conflicts is Procedure 5-C
below (Procedure 5-R from prior pack versions is folded into Procedure
5-C.1).

### Procedure 5.1 — Creating a custom agent

Triggered when the developer asks for a custom agent.

1. **Pre-check (G-design).** Verify no existing files for the proposed
   name (`.claude/agents/x-<name>.md`, the Codex and Gemini equivalents,
   and `docs/pack/prompts/x-<name>.md`). If any exist, route to
   Procedure 5.3 (completing a partial registration).
2. **Clarifying questions.** Purpose; which PLATFORM-SKILLS.md dimension
   this agent extends (Platform Targets, Languages, Component Roles, or
   Communication Protocols); primary phase served; read-only or write;
   Bash/Web/MCP tool requirements; number of prompt variants; existing
   pack skills loaded vs. new custom skill; which pack agent the PM chat
   would have routed to absent this custom (for the routing-table row).
3. **Drafts (G-files).** PM chat drafts all four files (Claude agent,
   Codex agent, Gemini agent, per-agent prompt). Presents side-by-side;
   iterate until approved.
4. **Registration drafts (G-registration).** PLATFORM-SKILLS.md
   `## Custom agents` row; trinity Phase routing rows in CLAUDE.md,
   AGENTS.md, and GEMINI.md (TRIO — byte-identical row content); if the
   new agent needs a custom skill, also draft a `## Custom skills` row
   plus three `SKILL.md` files (`.claude/skills/x-<name>/SKILL.md` and
   the Codex/Gemini equivalents).
5. **Commit (G-commit).** PM chat presents `git add` list and commit
   message; developer explicitly approves per CLAUDE.md pack rule. One
   commit, all artifacts.

### Procedure 5.2 — Creating a custom skill (standalone)

Triggered when an existing pack or `x-` custom agent will load a new
project-specific skill and no custom-agent creation is in flight.

1. **Pre-check:** no `x-<name>` skill directory exists in any of the
   three tool skills directories.
2. **Clarifying questions:** purpose; which PLATFORM-SKILLS.md dimension
   this skill extends (Platform Targets, Languages, Component Roles, or
   Communication Protocols); which agents load it; `allowed-tools`.
3. **Drafts (G-files):** three `SKILL.md` files with identical
   frontmatter and body across the three tool directories.
4. **Registration drafts (G-registration):** PLATFORM-SKILLS.md
   `## Custom skills` row naming which agents load the skill.
5. **Commit (G-commit):** per Procedure 5.1 step 5.

### Procedure 5.3 — Completing a partial registration (Unregistered)

Triggered when the detection scan reports an Unregistered custom agent
or skill (some but not all expected artifacts are present on disk).

1. PM chat lists present files and missing artifacts.
2. Developer approves reconstruction. PM chat drafts missing tool forms,
   prompt file, and/or PLATFORM-SKILLS.md row and routing-table entries.
3. **G-registration** approval.
4. **G-commit** approval.

### Procedure 5.4 — Adopting an improperly-added file

Triggered when the detection scan reports an Improperly added file —
present in one of the seven scan locations but with neither a name that
begins with `x-` nor an entry in the pack roster.

1. PM chat confirms the invisibility consequence: the file is on disk
   but not in routing tables or skill-load lists, so no agent session
   loads or invokes it.
2. Developer chooses:
   - **Adopt as custom.** Rename to `x-<name>`; route to Procedure 5.3
     to complete registration.
   - **Remove.** PM chat produces `git rm` commands for approval (per
     CLAUDE.md destructive-op rule: explicit approval before execution).
   - **Defer.** File stays on disk, stays invisible; scan flags it at
     every subsequent trigger.

### Procedure 5.5 — Detection scan as a phase-gate step

The phase-gate check in **Procedure 1** (METHODOLOGY.md) gains sub-step 5a:

> **5a. Run custom-file detection scan (Procedure 5).** If any
> unregistered or improperly-added files are found, pause and route to
> the appropriate sub-procedure (5.3 or 5.4). Developer may Defer; do
> not block the phase on unregistered custom files if the developer
> explicitly chooses Defer, but do not include those files in the
> upcoming prompt generation either.

### Procedure 5.6 — Registration reference tables

Custom-agent registration artifacts:

| Artifact | Location | Must exist before G-commit |
|---|---|---|
| Claude agent file | `.claude/agents/x-<name>.md` | Yes |
| Codex agent file | `.codex/agents/x-<name>.toml` | Yes |
| Gemini agent file | `.gemini/agents/x-<name>.md` | Yes |
| Per-agent prompt file | `docs/pack/prompts/x-<name>.md` | Yes |
| PLATFORM-SKILLS.md `## Custom agents` row | `docs/pack/PLATFORM-SKILLS.md` | Yes |
| Trinity routing-table row | `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (TRIO, byte-identical) | Yes |

Custom-skill registration artifacts:

| Artifact | Location | Must exist before G-commit |
|---|---|---|
| Claude skill | `.claude/skills/x-<name>/SKILL.md` | Yes |
| Codex skill | `.codex/skills/x-<name>/SKILL.md` | Yes |
| Gemini skill | `.gemini/skills/x-<name>/SKILL.md` | Yes |
| PLATFORM-SKILLS.md `## Custom skills` row | `docs/pack/PLATFORM-SKILLS.md` | Yes |

A developer can answer "is my custom agent / skill properly
registered?" by checking the rows above for their `x-<name>` entry.

---

## Procedure 5-C — Customization reconciliation after v9.3 → v10 migration

> **HISTORICAL — sunset in v11 (BD-121).** The v9->v10 migrator and
> its `MIGRATION-v9-to-v10.md` guide were removed in v11; this
> procedure no longer fires for new migrations. The v11 N->N+1
> migrator framework (BD-119, `scripts/lib/migrator-core.sh` +
> the BD-088 customization-preservation library) handles
> customization reconciliation differently — see
> `MIGRATION-v10-to-v11.md`. Procedure 5-C is retained here as
> historical documentation only; clients still on v9.x should
> reach out to the pack maintainer for migration guidance, or
> recover the legacy migrator from history with
> `git -C "$PACK" checkout v10 -- scripts/migrate-v9-to-v10.sh
> supporting-docs/MIGRATION-v9-to-v10.md`.

Triggered by presence of any `*.v9-customized` sidecar file in the
project working tree after `migrate-v9-to-v10.sh` (historical;
sunset in v11 — see HISTORICAL block above) completes.

A `*.v9-customized` sidecar means the migration script detected
project customization the migration could not safely auto-merge with
the v10 pack template. The v10 pack file has been written; the
project's pre-migration content is preserved in the sidecar; the
report lists the file under "Reconciliation required".

**Single-commit migration model.** The migration is one atomic
session: the script's mechanical pass and Procedure 5-C
reconciliation both happen on the working tree of the
`migration-v9-to-v10` branch *before any commit*. The session ends
in one of two outcomes:

- **Commit.** Reconciliation completes, all sidecars are removed,
  the working tree is clean. A single commit on
  `migration-v9-to-v10` captures the fully reconciled v10 state.
- **Rollback.** Reconciliation reveals a defect that cannot be
  resolved in-session, or the developer decides not to proceed.
  The working tree is restored to v9.3 (the migration branch's
  starting commit) and the branch is dropped. No commit is made.
  Repo state is exactly as it was before the migration ran.

This procedure does *not* split the migration across two commits.
Sidecars are never committed — they exist only on the working
tree, between the script's run and the final commit-or-rollback
decision. Steps 8–9 of `MIGRATION-v9-to-v10.md` (historical, available
via `git checkout v10 --` per the HISTORICAL block above) — merge to
default branch + `/pm-startup` for Procedure 5-S housekeeping — run
after the single migration commit.

Procedure 5-C is re-entrant *within the same migration*. If the
session ends mid-procedure (chat closes, machine restarts, etc.),
the unresolved sidecars remain on the uncommitted working tree.
A subsequent `/pm-startup` detects the sidecars and resumes the
procedure where it left off. The procedure is complete only when
every `*.v9-customized` sidecar is removed and the working tree is
ready for the single migration commit.

**Surface pack defects as you discover them.** If during
reconciliation you notice that the v10 pack template ships
incorrect content (wrong filenames, missing entries in tables,
misleading instructions, etc.), append a dated entry to
`docs/pack/PACK-FEEDBACK.md` *before* completing the procedure.
The PACK-FEEDBACK update is part of the same single migration
commit, not a follow-up. Format: one bullet per defect with
file/section reference and a short suggested correction. The
pack maintainer reads PACK-FEEDBACK.md to land fixes in the
next pack release.

### Procedure 5-C.0 — Pre-flight (read this first)

1. **Open the migration report.**
   `cat .pack-migration-backup/v9.3-to-v10.0/report.md`. Read the
   "Reconciliation required" section. Each entry names the migrated
   file, the sidecar path, the three-way diff path, and a one-line
   reason for the reconciliation.
2. **Inventory sidecars.** From the project root:
   `find . -name '*.v9-customized' -not -path './.pack-migration-backup/*'`.
   The list must match the "Reconciliation required" section of the
   report one-for-one. A mismatch is a defect — STOP and surface it
   to Pack Chat before proceeding.
3. **Confirm the migration branch and uncommitted state.**
   `git branch --show-current` must print `migration-v9-to-v10` (or
   whatever branch the migration created). Procedure 5-C does not
   run on `main`. The branch must NOT contain any migration commit
   yet — verify with `git log --oneline main..HEAD`, which must be
   empty. The mechanical migration changes live on the uncommitted
   working tree; they become a commit only at the end of 5-C.9. If
   `git log main..HEAD` is non-empty, a commit was made
   prematurely (in violation of the single-commit model); stop and
   surface this to the developer before proceeding — the procedure
   can still complete and produce a second commit, but the protocol
   was breached and the developer should be aware.
4. **Decide reconciliation strategy per file class.** The flow below
   branches by file class (per the disposition record's `class` column
   in `dispositions.tsv`). Process files in the order they appear in
   the report — the order is class-grouped (text-prose first, then
   structured configs, then agents/skills, then scripts) so the
   developer establishes context once per class.

### Procedure 5-C.1 — Prompt-templates reconciliation (legacy D4 case)

Triggered when the migration's S6 stage produced
`docs/pack/PROMPT-TEMPLATES.md.v9-customized` — the v10 retirement of
`docs/pack/PROMPT-TEMPLATES.md` for projects whose v9.3 file diverged
from the v9.3 pack baseline (i.e., the project edited the
PROMPT-TEMPLATES content). This sub-procedure folds the former
Procedure 5-R from METHODOLOGY.md into Procedure 5-C with unified
sidecar naming.

The PROMPT-TEMPLATES.md file is retired by design in v10 — its
content distributes across `docs/pack/prompts/<agent>.md` per-agent
prompt files. The sidecar preserves the project's v9.3 customization
so the developer can redistribute the project-specific edits into the
new per-agent prompt structure.

(Pre-C7 installs may have a sidecar at
`docs/pack/prompts/_v9-backup.md` instead. The procedure below works
identically — substitute the legacy path. The inventory step in
Procedure 5-C.9 explicitly checks for the legacy filename so neither
shape is missed.)

1. **Read the sidecar.**
   `cat docs/pack/PROMPT-TEMPLATES.md.v9-customized`. The file contains
   the project's v9.3 PROMPT-TEMPLATES.md verbatim — pack-baseline
   sections plus project edits intermixed.
2. **Read the v10 per-agent prompt files.** `ls docs/pack/prompts/`.
   The v10 per-agent prompts (`coder.md`, `reviewer.md`, `tester.md`,
   etc., plus the `pm-chat.md` variants) contain the v9.3 baseline
   content reshaped per agent. The meaningful diff between the sidecar
   and the v10 pack content is the project-specific customization —
   the same content that the v9.3 pack shipped is already represented
   in the v10 per-agent files modulo reformatting.
3. **PM chat surfaces each project customization with proposed
   placement.** For example: "your project added X to Template 4; in
   v10 this would live in `coder.md ## Variant: fix-cycle` between
   these lines. Approve?" PM chat reads the existing per-agent file
   and proposes the insertion point based on the v10 prompt-section
   convention (METHODOLOGY.md Part 5 § Mandatory section structure).
4. **Developer approves, modifies, or rejects each surfaced item.**
   For project-specific customizations that don't fit into a
   pack-roster prompt section, the developer may opt to land the
   content in a project `x-<agent>.md` variant or in
   `PACK-FEEDBACK.md` for upstream consideration.
5. **PM chat writes approved changes to the relevant per-agent
   file(s).** One write per file; no bulk rewrites. Each write is
   confirmed before the next.
6. **Delete the sidecar.**
   `rm docs/pack/PROMPT-TEMPLATES.md.v9-customized` (or the legacy
   `docs/pack/prompts/_v9-backup.md` for pre-C7 installs).
   Procedure 5-C.1 does not run again. The reconciliation is
   recorded in the migration commit message per Procedure 5-C.9.

Procedure 5-C.1 differs from 5-C.2–5-C.8 in two ways:

- **No file under the original path.** v10 retires
  `docs/pack/PROMPT-TEMPLATES.md`; the sidecar sits beside the
  retired path but no live file pairs with it.
- **Cross-file redistribution.** The reconciliation lands content
  into multiple per-agent prompt files, not back into the original
  file's location. This is the only sub-procedure where reconciled
  content moves to a different path than where the sidecar sits.

Both differences are accommodated by the same sidecar / report /
clear-and-commit mechanism as the other sub-procedures.

### Procedure 5-C.2 — Trinity prose (C1 / C2 / C3)

Files: `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (sidecar:
`<file>.v9-customized`). Pattern: P (intermixed prose under pack-named
H2 sections).

The migration produced `<file>.v9-customized` for each trinity file
where v9.3 OURS differed from the v9.3 BASE and the v10 pack also
changed the file. The v10 pack file has been written; the project's
v9.3 prose is preserved in the sidecar.

The trinity rule applies throughout: every reconciliation decision is
made once and applied to all three files (CLAUDE.md / AGENTS.md /
GEMINI.md) with byte-identical content under each H2 the trinity rule
covers. The only allowed asymmetry is tool-intrinsic content (Claude
Task tool syntax, Codex profile names, Gemini agent invocation
syntax) — and only inside H2 sections that are themselves marked as
tool-specific.

1. **Open the three-way diff.**
   `cat .pack-migration-backup/v9.3-to-v10.0/diffs/<file>.three-way.diff`
   (path from the report). The diff shows BASE (v9.3 pack baseline) →
   OURS (project v9.3 customization) → THEIRS (v10 pack template).
2. **Reconcile the preamble** (everything above the first H2 — H1
   title, intro paragraph, and any HTML comment blocks). The v10
   template ships with fresh-install scaffolding the live file
   should *not* retain after migration:

   - **Remove the `<!-- HOW TO USE THIS TEMPLATE -->` comment block.**
     v10 ships this block in trinity templates for *new-project*
     setup. After migration the project already exists; the block
     is noise. Delete it from all three live trinity files.
   - **Restore the H1 title from the sidecar.** The v10 template
     ships `# CLAUDE.md` (or `# AGENTS.md` / `# GEMINI.md`). The
     v9.3 sidecar typically has the project name appended
     (`# CLAUDE.md — <ProjectName>`). Replace the live H1 with the
     sidecar's H1 across all three files.
   - **Replace placeholders with sidecar values.** The v10 template
     contains `[PROJECT_NAME]`, `[PLATFORM_TARGETS]`, `[TRANSPORT]`,
     and conditional placeholders like `[PLATFORM_DEFAULTS]`,
     `[PLATFORM_ARCHITECTURE]`, `[LANGUAGE_RULES]`, `[GRPC_RULES]`,
     `[PLATFORM_SECURITY]`, `[PLATFORM_TESTING]`,
     `[PLATFORM_ANTIPATTERNS]`. For each placeholder still present
     in the live file, find the corresponding filled-in value in
     the sidecar and substitute it. Apply identically across all
     three trinity files.
   - **Restore the project intro paragraph.** The text immediately
     after the H1 (e.g., "This repository is a macOS-only
     algorithmic trading prototype...") is project-specific.
     Replace any v10 template intro with the sidecar's intro,
     consistently across all three files.

   The Active-skills line and `## Project addenda` H2 are pack-
   structural and may already be in place from S5's marker-section
   splice — leave them unless reconciliation specifically requires
   editing them.
3. **Walk each H2 section in the project's v9.3 file.** Open
   `<file>.v9-customized` in the editor alongside the live `<file>`
   (now containing the v10 template). For each H2 in the v9.3 file:
   a. **H2 also exists in v10 template.** Read the v9.3 body, read
      the v10 body. Decide one of:
      - **Keep pack.** v10 supersedes v9.3 for this section
        (e.g., the section is a methodology summary the pack tightened
        and the project has no domain-specific override). No edit
        needed; the v10 template is already in place.
      - **Keep project.** The v9.3 body is project-specific
        (architecture rules tuned to the codebase, security policy,
        anti-patterns the team learned). Replace the v10 body under
        this H2 with the v9.3 body from the sidecar. Apply the same
        replacement to all three trinity files.
      - **Hand-merge.** Both contain content that must survive.
        Compose a merged body — pack scaffolding plus project
        additions — and replace the v10 body with the merged result.
        Apply identically across the three files.

      *Special case — `[CONDITIONAL]` sections whose v10 body is just a
      `[PLATFORM_*]` / `[LANGUAGE_RULES]` / `[GRPC_RULES]` placeholder.*
      The placeholders are *not* meant to be filled by copying skill
      content into the trinity — skills are loaded at runtime by
      agent prompts and are the canonical source. For these sections:
      - **If v9 has project-specific filled-in content** (project
        types named, project rules referenced): keep project + rename
        the H2 to drop `[CONDITIONAL]`.
      - **If v9 has no content for this section**: delete the section
        across all three trinity files. Skills supply the rules at
        agent runtime.
      Do not "fill from skills" — that creates a duplicated source of
      truth that drifts with every skill update.
   b. **H2 is project-original (not in v10 template).** Two routes:
      - **Pack-worthy.** The customization should be upstreamed.
        Land the section under `## Project addenda` at the bottom
        of the v10 template (the v10 template ships the H2 marker
        empty — see C9 commit). File a `PACK-FEEDBACK.md` entry per
        Workflow 10 / Part 10 of METHODOLOGY.md proposing the
        addition to the pack.
      - **Project-only.** Land the section under `## Project addenda`.
        No PACK-FEEDBACK entry.
4. **Walk each H2 section in v10 that is NOT in the v9.3 file.** These
   are pack additions the project must adopt or consciously reject.
   Default action is **adopt** — the v10 template is already in place.
   If the project explicitly does not want the section (e.g., it
   conflicts with project policy), delete the section from all three
   trinity files and record the rejection in `BACKLOG.md` so a future
   migration does not silently re-introduce it.
5. **Strip `[CONDITIONAL]` prefix from retained sections.** The v10
   pack templates use `[CONDITIONAL]` in H2 names to signal "decide
   whether to keep this section." Once you have decided to keep a
   section, the prefix is misleading scaffolding. Remove `[CONDITIONAL] `
   from any retained H2 (consistently across all three trinity files).
   Drop sections you do not keep. Examples after this step:
   - `## [CONDITIONAL] iOS 26 / Xcode 26.3 platform features` →
     `## iOS 26 / Xcode 26.3 platform features` (or rename per project)
   - `## [CONDITIONAL] Anti-patterns — never introduce these` →
     `## Anti-patterns — never introduce these`
6. **Trinity rule check (HARD GATE).**
   ```
   diff <(grep '^## ' CLAUDE.md) <(grep '^## ' AGENTS.md)
   diff <(grep '^## ' CLAUDE.md) <(grep '^## ' GEMINI.md)
   ```
   The first diff must be empty. The second may show only the
   documented Gemini-intrinsic exceptions (`## Agent roster`,
   `## Gemini CLI operating notes`). Any other divergence — even a
   single H2 — is a trinity-rule violation. **Do not proceed past
   this step until both diffs are clean. If a diff is non-empty,
   return to the offending section and apply the same decision
   identically across all three trinity files.** Truncated bash
   output is not a pass; read the full diff text before declaring
   the check passed.
7. **Confirm no placeholders remain.**
   ```
   grep -nE '\[(PROJECT_NAME|PLATFORM_TARGETS|TRANSPORT|PLATFORM_DEFAULTS|PLATFORM_ARCHITECTURE|LANGUAGE_RULES|GRPC_RULES|PLATFORM_SECURITY|PLATFORM_TESTING|PLATFORM_ANTIPATTERNS)\]' CLAUDE.md AGENTS.md GEMINI.md
   ```
   Must produce no output. Any remaining placeholder is an unfinished
   preamble or section step — return and complete it.
8. **Delete the sidecars.**
   `rm CLAUDE.md.v9-customized AGENTS.md.v9-customized GEMINI.md.v9-customized`.
   Procedure 5-C does not consider trinity reconciliation complete
   until all three sidecars are gone.

### Procedure 5-C.3 — PM-CHAT.md (D1)

File: `docs/pack/PM-CHAT.md` (sidecar:
`docs/pack/PM-CHAT.md.v9-customized`). Pattern: T (template) → P
(intermixed prose after kickoff fill).

PM-CHAT.md is a template at install time; the kickoff (Procedure 7)
fills `[PROJECT_NAME]` and the "Additional project documents" section.
After kickoff, the file is intermixed prose under pack-named headings.
The migration's classifier detects the post-kickoff state via the
`[PROJECT_NAME]` placeholder absence and the populated additional-docs
section.

1. Open `docs/pack/PM-CHAT.md.v9-customized` and the live
   `docs/pack/PM-CHAT.md` side by side.
2. **Reconcile the preamble** (everything above the project H1
   `# [PROJECT_NAME] — PM Chat Instructions`):

   - **Remove the `<!-- HOW TO USE THIS TEMPLATE -->` comment block.**
     v10 ships this for *new-project* setup; the project already
     exists post-migration.
   - **Remove the italicized `*Copied from: project-template/...*`
     block.** Same rationale — it's setup scaffolding the v10
     template ships for fresh installs only.
   - The document H1
     (`# PM-CHAT.md — PM Chat Startup and Operating Instructions`)
     is pack-controlled and stays unchanged.
3. **Project name (H1).** The v9.3 file's project H1 has the
   literal project name; the v10 file has `[PROJECT_NAME]`. Replace
   the placeholder with the project name from the sidecar. (If
   Procedure 5-S Task B has already run and substituted the
   placeholder, this step is a no-op — confirm and continue.)
4. **Role paragraph.** v9.3 had a "You are the PM for X" sentence
   plus optional project-specific role description. v10 has the
   pack-template role paragraph with `[PROJECT_NAME]` token. Decide:
   keep-pack (replace token only), keep-project (paste sidecar
   paragraph), or hand-merge (template scaffold plus project
   specifics).
5. **Additional project documents section.** This is the most common
   conflict point. v10 ships an empty / illustrative list; v9.3 has
   the project's filled list of project-specific docs. Replace the
   v10 list wholesale with the sidecar's list.
6. **Walk remaining H2 / H3 sections.** Apply the same H2-walk logic
   as trinity (5-C.2 step 3) — keep-pack / keep-project / hand-merge
   per section.
7. **Confirm no placeholders remain.** Two checks — both must pass:
   ```
   grep -nE '\[(PROJECT_NAME|project|project-short-name)\]' docs/pack/PM-CHAT.md
   grep -nF '/path/to/your-project' docs/pack/PM-CHAT.md
   ```
   Both commands must produce no output. PM-CHAT.md uses three
   placeholder shapes that all need to be filled in:
   - `[PROJECT_NAME]` — full project name in headings.
   - `[project-short-name]` — CLI session tag, e.g., `claude --resume
     [project-short-name]-pm`.
   - `/path/to/your-project` — project directory in `cd` examples
     (path-style placeholder; not bracketed).
   All three forms must be substituted with the project's
   filled-in values from the sidecar.
8. **Delete the sidecar.** `rm docs/pack/PM-CHAT.md.v9-customized`.

PM-CHAT.md is not under the trinity rule; no cross-file symmetry
check applies.

### Procedure 5-C.4 — PLATFORM-SKILLS.md (D2)

File: `docs/pack/PLATFORM-SKILLS.md` (sidecar:
`docs/pack/PLATFORM-SKILLS.md.v9-customized`). Pattern: X
(marker-section) — sidecar appears only when the v9.3 project lacked
the v10 marker convention OR the auto-splice produced warnings.

The migration's `merge-platform-skills.py` helper splices the
project's `## Custom agents` and `## Custom skills` regions verbatim
into the v10 template. v9.3 projects do not have those sections, so
the splice writes the v10 template verbatim — but the project may
have edited rows above the `## Custom *` boundary (active-skills
tuning) that the splice does not preserve. The sidecar captures
those edits.

1. **Confirm the auto-splice preserved Pattern X regions.**
   `diff <(awk '/^## Custom agents/,0' docs/pack/PLATFORM-SKILLS.md.v9-customized) <(awk '/^## Custom agents/,0' docs/pack/PLATFORM-SKILLS.md)`.
   The diff should be empty (no edits to Custom regions during
   migration). If the diff is non-empty, the auto-splice failed —
   STOP and surface to Pack Chat.
2. **Reconcile non-Pattern-X edits.** Diff the pre-`## Custom agents`
   region of the sidecar against the same region of the live file.
   Any diff is a project edit the auto-splice did not preserve.
   Decide keep-pack / keep-project / hand-merge per row.
3. **Adopt v10 marker convention.** If the v9.3 file had no
   `## Custom agents` / `## Custom skills` heading, the v10 file now
   has both empty (or with the project's pre-existing custom rows if
   the project added rows in non-Pattern-X form). Verify the
   project's actual custom agents and skills (from
   `.claude/agents/x-*.md`, `.claude/skills/x-*/`) have rows under
   the new headings. Add rows for any missing entries.
4. **Delete the sidecar.** `rm docs/pack/PLATFORM-SKILLS.md.v9-customized`.

### Procedure 5-C.5 — Structured configs (K1 / K2 / K3 / K4)

Files: `.claude/settings.json` (K1), `.codex/config.toml` (K2),
`.codex/requirements.toml` (K3 if shipped), `.mcp.json.example` (K4).
Pattern: S (semantic structured merge).

The migration's `merge-json.py` and `merge-toml.py` helpers compute a
key-level three-way merge. A sidecar appears only when the helpers
hit an ambiguous case (project-removed AND pack-added the same item;
type mismatch across BASE / OURS / THEIRS; structural conflict). When
a sidecar appears, the helpers also write a warnings log at
`.pack-migration-backup/v9.3-to-v10.0/diffs/<file>.merge-warnings.log`
listing each unresolved key.

1. **Read the warnings log.**
   `cat .pack-migration-backup/v9.3-to-v10.0/diffs/<file>.merge-warnings.log`.
   Each warning names a key path, the BASE / OURS / THEIRS values,
   and the conflict type.
2. **Resolve each warning.** For each:
   a. **Project-removed AND pack-added the same item.** Decide
      whether the project's removal was intentional (e.g., the
      project removed `[model_providers.ollama]` because it does
      not run a local Ollama instance). If intentional, leave the
      live file as-is (the merge defaulted to including the item;
      remove it manually). If not intentional, the merge default
      stands — no edit needed.
   b. **Type mismatch.** A key was a string in v9.3, a list in v10.
      Read the v10 schema (in the pack template comment header or
      in `V10-DESIGN.md`); decide the correct value shape. Edit the
      live file.
   c. **Structural conflict.** A whole table (TOML) or object
      (JSON) has divergent shape. Open the sidecar, the live file,
      and the BASE (from `git -C $PACK show v9.3:<path>` per the
      migration's three-way materials). Hand-resolve.
3. **Validate the resulting file.** For JSON:
   `python3 -m json.tool < <file> > /dev/null`. For TOML:
   `python3 -c "import tomllib; tomllib.load(open('<file>','rb'))"`.
4. **Apply trinity rule for tool-config parity (per BD-059 success
   criterion).** If the reconciled file affects an
   `AGENT_CAPABILITIES`-class key (env in `.claude/settings.json`,
   `[agent_capabilities]` table in `.codex/config.toml`,
   `.gemini/.env`), confirm the same value is expressed in all three
   tools' configs. The migration's parity check warns if not;
   resolve before proceeding.
5. **Delete the sidecar.** `rm <file>.v9-customized`.

### Procedure 5-C.6 — Pack agents (A1–A3) and pack skills (L1–L3)

Files: `.{claude,codex,gemini}/agents/<roster>.{md,toml}` (sidecar:
sibling `<file>.v9-customized`);
`.{claude,codex,gemini}/skills/<roster>/SKILL.md` (sidecar:
`SKILL.md.v9-customized` inside the skill dir). Pattern: P
(intermixed pack content with project additions).

Project-edited pack agents and pack skills are uncommon but legitimate
(e.g., a project that hand-tuned `auditor-architecture.md` with a
domain-specific review checklist bullet). The sidecar captures the
project edits; the live file has the v10 pack version.

1. **Diff the sidecar against the live file.**
   `diff <file>.v9-customized <file>`. The diff shows project
   additions / removals against the v10 pack version.
2. **Decide per addition.** For each project addition:
   - **Port forward.** Re-apply the addition on top of the v10 pack
     file (the addition is project-specific and should remain in
     the project's copy of the pack file).
   - **Upstream.** File a `PACK-FEEDBACK.md` entry proposing the
     addition. After upstreaming, the addition lands in a future
     pack version and the project's local edit can be removed at
     the next migration.
   - **Drop.** v10 supersedes the project edit (the pack changed
     for a reason that obsoletes the project's customization).
3. **Trinity-symmetry check for agents.** The same edit applied to
   one tool's variant (e.g., `.claude/agents/coder.md`) must be
   applied to the Codex `.codex/agents/coder.toml` and Gemini
   `.gemini/agents/coder.md` equivalents — UNLESS the change is
   tool-intrinsic (Claude Task tool reference, Codex profile name,
   Gemini YAML frontmatter shape). The trinity rule applies to pack
   agent files identically to the trinity prose files.

   Use `scripts/compare-agent-trinity.py <agent-name>` to verify
   parity after porting an edit forward. The comparator parses each
   tool's agent file (Claude Markdown + frontmatter, Codex TOML
   `developer_instructions`, Gemini Markdown + frontmatter),
   normalizes whitespace and Markdown formatting, and reports body
   divergence. Run with `--strict` to flag stylistic differences too.
   Resolve any unintended divergence before deleting the sidecars.

4. **Skill-dir siblings.** A skill directory may contain files
   beyond `SKILL.md` (project notes, supporting docs). The migration
   preserves siblings in place; only `SKILL.md` is reconciled. If
   the v10 pack ships new sibling files for a skill, they appear
   alongside the project's pre-existing siblings — confirm no name
   collision and adopt the new pack siblings.
5. **Delete the sidecar.** `rm <file>.v9-customized` (or
   `rm <skill-dir>/SKILL.md.v9-customized`).

### Procedure 5-C.7 — Scripts (S1, S2)

Files: `agent-run.sh` (S1), `scripts/<script>.sh` for pack-roster
scripts (S2). Sidecar: `<file>.v9-customized` alongside. Pattern: P
(pack-shipped scripts with possible project edits).

Project-edited pack scripts are uncommon (most projects accept the
pack scripts unchanged). When sidecars appear:

1. **Diff sidecar against live.** `diff <file>.v9-customized <file>`.
2. **Decide per change.** Same options as 5-C.6 step 2 — port
   forward, upstream, drop.
3. **Project-only `x-*.sh` scripts.** S2/S3 preserve `scripts/x-*.sh`
   in place automatically; they do not produce sidecars. Confirm
   their presence with `ls scripts/x-*.sh` (the report's "Project
   files preserved" section also lists them). No reconciliation
   action is required for `x-*.sh` scripts unless the project chose
   to retire one — in which case `git rm` on developer approval per
   CLAUDE.md destructive-op rule.
4. **Delete the sidecar.** `rm <file>.v9-customized`.

### Procedure 5-C.8 — Per-agent prompts (P1)

Files: `docs/pack/prompts/<roster>.md` (sidecar: sibling
`<file>.v9-customized`). Pattern: P.

When the project edited a pack-roster prompt file (rare — most prompt
edits go in `docs/pack/prompts/x-*.md` project additions), the
migration preserves the project edit as a sidecar and writes the v10
pack version live.

Apply the trinity-prose flow (5-C.2 H2 walk) to the prompt file.
Per-agent prompt files are not under the trinity rule (one file per
agent, not a tool trinity).

1. Open the sidecar and the live prompt file.
2. Walk each named section (Variant: standard, Variant: fix-cycle,
   etc.). Decide keep-pack / keep-project / hand-merge.
3. Project-original sections (a variant the v10 pack template doesn't
   have) belong in `docs/pack/prompts/x-<agent>-<variant>.md` per the
   `x-*` convention, not appended to the pack-roster file. Move the
   section there if needed.
4. Delete the sidecar.

### Procedure 5-C.9 — Completion check and commit

After every sidecar has been reconciled and removed:

1. **Inventory check.** From the project root:
   `find . -name '*.v9-customized' -not -path './.pack-migration-backup/*'`.
   Output must be empty.
2. **Legacy-name check (transitional).**
   `find . -name '_v9-backup.md' -not -path './.pack-migration-backup/*'`.
   Output must be empty (relevant only on installs that ran a pre-C7
   v10.0 migration).
3. **Report check.** Re-read the "Reconciliation required" section
   of `report.md`. The developer maintains a checklist alongside the
   report (in the editor or as a scratch file at
   `.pack-migration-backup/v9.3-to-v10.0/reconcile-checklist.md`)
   confirming each entry has been addressed. Each entry must be
   marked done.
4. **Working-tree review.** `git status` and `git diff` on the
   migration branch. Confirm the working tree contains no
   `*.v9-customized` files and matches developer intent.
5. **Pack `.example` files trackable check.** v10 ships several
   `.example` files (`.gemini/.env.example`, `.codex/config.toml.example`,
   `.mcp.json.example`) that the pack expects to be committed.
   Confirm none of them are silently ignored by `.gitignore`:

   ```bash
   for f in .gemini/.env.example .codex/config.toml.example .mcp.json.example; do
       if [[ -f "$f" ]] && git check-ignore -q "$f"; then
           echo "FAIL: $f is gitignored — pack expects it tracked"
           git check-ignore -v "$f"
       fi
   done
   ```

   If any line is reported, the project's `.gitignore` is
   suppressing a pack-tracked file. The migration script's S0 step
   ensures the `.env.*` exception is applied automatically — if a
   pack `.example` file is still ignored, the project's `.gitignore`
   has additional rules that need an exception. Fix the `.gitignore`
   on the working tree (typically by adding `!<filename>` after the
   matching ignore rule) before commit.
6. **Re-run validation.** Run `./scripts/bootstrap.sh` and
   `./scripts/validate.sh` (or the project's equivalent) and
   confirm clean. If validation fails, the reconciliation
   introduced a regression — fix in the working tree before
   proceeding. Do not commit a failing migration.
7. **Single migration commit.** This is the *sole* commit on the
   migration branch. `git add -A` to stage all migrated files,
   reconciled content, new pack files (e.g.,
   `docs/pack/INSTALL-PROCEDURES.md`, `docs/pack/prompts/`,
   `.codex/config.toml.example`, `.gemini/settings.json`), any new
   `## Project addenda` sections, `x-*.md` prompts, and
   `PACK-FEEDBACK.md` additions. Verify `git status` shows no
   `*.v9-customized` files staged or untracked, and no
   `_v9-backup.md` file.

   Suggested commit message:
   `feat: v10 — migrate from v9.3 (script + Procedure 5-C reconciliation)`.

   After commit, follow `MIGRATION-v9-to-v10.md` (historical,
   available via `git checkout v10 --`) Step 8 to merge the branch
   into the default branch, then Step 9 to run `/pm-startup` and let
   Procedure 5-S clear the post-migration sentinel. Procedure 5-C
   does not run again on this project.

### Rollback (instead of commit)

If reconciliation reveals a defect that cannot be resolved
in-session, or the developer decides not to proceed, abort
cleanly — the migration leaves no committed trace:

```bash
# 1. Discard all working-tree changes from the migration
git checkout -- .
git clean -fd

# 2. Remove the migration backup directory
rm -rf .pack-migration-backup

# 3. Return to the default branch and drop the migration branch
git checkout main
git branch -D migration-v9-to-v10
```

After rollback the working tree, branches, and history are
exactly as they were before the migration ran. Re-run the
migration when the underlying defect is fixed (typically in the
pack scripts or docs, then a `git pull` of the pack updates,
followed by re-running the migration prompt).

### Completion-check assertions (machine-checkable)

A developer (or the `pm-startup` SKILL Step 0 hook) can verify
Procedure 5-C is complete by running all four assertions:

**Assertion A — No `.v9-customized` sidecars in working tree.**

```bash
test -z "$(find . -name '*.v9-customized' \
    -not -path './.pack-migration-backup/*' \
    -not -path './.git/*')"
```

**Assertion B — No legacy `_v9-backup.md` under `docs/pack/prompts/`.**

```bash
test ! -f docs/pack/prompts/_v9-backup.md
```

**Assertion C — Reconciliation rows in `dispositions.tsv` all
addressed.** Each row with disposition
`customization-detected-needs-reconciliation` (or `removed-by-design`
with a non-empty sidecar field) requires reconciliation. Verify each
such row's sidecar is absent from disk (per Assertion A) AND has a
corresponding entry in the developer's reconciliation checklist
marked done.

**Assertion D — Working tree on migration branch and commit-ready.**

```bash
test "$(git branch --show-current)" = "migration-v9-to-v10"
test -z "$(git diff --name-only -- '*.v9-customized')"
```

All four assertions must pass before the migration commit lands.

---

## Procedure 5-S — Post-migration housekeeping

> **HISTORICAL — sunset in v11 (BD-121).** This procedure was
> triggered by the v9->v10 migrator's S7 sentinel; the migrator
> was removed in v11. The v11 N->N+1 migrator framework handles
> post-migration housekeeping inline (no separate procedure
> needed for v10->v11). Procedure 5-S is retained here as
> historical documentation only.

Triggered by presence of
`.pack-migration-backup/v9.3-to-v10.0/postrun-pending` at PM chat
startup. Written by `migrate-v9-to-v10.sh` (historical; sunset in v11
— see HISTORICAL block above) stage S7. Combines two
post-migration housekeeping tasks; either may report "nothing to do"
without defect. Procedure is re-entrant — partial completion preserves
the sentinel and re-runs at next `/pm-startup`.

| Task | Scope | Action |
|---|---|---|
| **A** | STATUS.md pack-version markers (F-E) | Search `docs/project/STATUS.md`, then `docs/STATUS.md`, then `STATUS.md` (first existing wins). Grep case-insensitively for lines containing both `AI Agent Config Pack` (or `Pack version`) and a `v9` token. For each match, propose updating the version to the current pack version (read from `docs/pack/METHODOLOGY.md` first 5 lines, matching pm-startup Step 6). Developer approves / edits / skips per match. If no STATUS.md found or no v9 markers found: report "Task A — nothing to do." |
| **B** | Trinity placeholder reconciliation (F-F) | Grep `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` for occurrences of the closed-form whitelist: `[PROJECT_NAME]`, `[PLATFORM_TARGETS]`, `[TRANSPORT]`, `[PLATFORM_DEFAULTS]`, `[PLATFORM_ARCHITECTURE]`, `[LANGUAGE_RULES]`, `[GRPC_RULES]`, `[PLATFORM_SECURITY]`, `[PLATFORM_TESTING]`, `[PLATFORM_ANTIPATTERNS]`. Also grep for the literal Active-skills placeholder line (`Active skills: [PM chat writes`). For project-identifier placeholders, ask the developer for the values (project name, platform targets, transport) and offer to fill them consistently across all three trinity files (TRIO — byte-identical content). For section placeholders, reference the loaded skills' content. For the Active-skills line, run a simpler standalone Q&A (NOT the full Procedure 7 kickoff flow): "What skills are active for this project? Read `docs/pack/PLATFORM-SKILLS.md` to see options. PM chat proposes the set based on project type; developer approves." If no whitelist matches found and Active-skills line is filled: report "Task B — nothing to do." |

1. Detect sentinel; read `docs/pack/METHODOLOGY.md` first 5 lines for
   current pack version (Task A reference value).
2. Run Task A. Surface findings (or "nothing to do"); apply
   developer-approved edits to STATUS.md.
3. Run Task B. Surface findings (or "nothing to do"); apply
   developer-approved edits to the trinity files (TRIO; byte-identical
   across CLAUDE.md / AGENTS.md / GEMINI.md for every section the
   trinity rule covers).
4. If both tasks completed (no deferred items remain), PM chat offers
   to remove the sentinel
   `.pack-migration-backup/v9.3-to-v10.0/postrun-pending` and records
   the housekeeping in the commit message. Once removed, Procedure
   5-S does not run again. If either task has deferred items, leave
   the sentinel in place — Procedure 5-S re-runs at next
   `/pm-startup`, re-scans (skipping items already addressed), and
   resurfaces the rest.

---

## Procedure 7 — Kickoff auto-discovery and install-check

Triggered when the developer pastes the `Variant: kickoff` prompt
from `docs/pack/prompts/pm-chat.md` on a shell-capable surface
(Claude Code CLI, Codex CLI, Gemini CLI, Claude Desktop with Desktop
Commander) and declares `shell` at the surface-declaration gate.

Procedure 7 is the PM-chat-side companion to the kickoff-variant
continuation pointer. The pointer routes to this procedure; this
procedure fills in the Apple / gRPC toolchain that SETUP-NEW.md
Steps 5–8 would otherwise require the developer to run by hand.
Every auto-discovered value and every install / edit / machine-level
write is confirmed via Form R / I / E / M before the PM chat acts.

Gates: **G7-discovery** (Form R), **G7-install** (Form I),
**G7-edit** (Form E), and **G7-machine** (Form M). Each gate defaults
to `skip` except G7-discovery, which is read-only and defaults to
`yes`.

### 7.0 Trigger and scope

The PM chat enters Procedure 7 once the assistant has (a) declared
its surface and (b) given the developer a one-message exit ramp
before any non-read-only action. On a shell-capable surface (Claude
Code CLI, Codex CLI, Gemini CLI, Claude Desktop with Desktop
Commander), the assistant typically declares `shell` by inference
from its environment — this is sanctioned and not a deviation; it
MUST NOT begin Form R discovery in the same message as the surface
declaration. On Web / Desktop surfaces without shell access (Claude
Web, ChatGPT Web), the assistant declares `manual`; Procedure 7 is
not entered; the PM chat emits the `SETUP-NEW.md § Manual fallback`
pointer and waits for developer-reported values. The exit-ramp
reply is interpreted per the § 7.5 reply grammar (`yes` / `no` /
`skip` / `abort` / `edit` / bare value); a positive reply
authorizes Form R, anything else defers per the grammar's
"unrecognized → no" rule.

The developer may declare `manual` even on a shell-capable surface
(e.g., to read the planned commands before granting execution); the
PM chat honors it. The developer may also switch to `manual`
mid-kickoff; the PM chat treats that as a re-declaration from that
point onward — commands already run cannot be unrun.

### 7.1 K1 — read-only discovery (Form R, G7-discovery)

```
PROPOSED ACTION — read-only discovery
  All commands below are read-only (no side effects). If a command
  is not applicable to this project (e.g., Xcode on a Python-only
  project), the command exits non-zero; I note that and continue.

  Apple / Swift discovery:
    1. xcodebuild -list
    2. xcrun simctl list devices available
    3. command -v swift-format; if present, swift-format --version

  gRPC discovery:
    4. command -v buf;                    if present, buf --version
    5. command -v protoc-gen-swift;       if present, --version
    6. command -v protoc-gen-grpc-swift;  if present, --version

  Environment:
    7. command -v brew; if present, brew --version

  Python + gRPC discovery (only if Python detected):
    8. command -v uv;      if present, uv --version
    9. command -v python3; if present, python3 --version

  Machine-level companion files:
   10. ls -1 ~/Library/Developer/Xcode/CodingAssistant/ 2>/dev/null
   11. ls -1 "$PACK/xcode-companion-templates/"

Reply: `yes` to run all · `skip` to bypass auto-discovery
       (I'll ask you manually for each value) · `abort` to stop kickoff
```

### 7.2 K2 — Apple sub-flow

Runs only if `[PLATFORM_TARGETS]` includes any of iOS, iPadOS, macOS,
tvOS, watchOS, or visionOS. Otherwise skipped with a single-line note.

#### 7.2.1 Xcode scheme and destination

From `xcodebuild -list`:
- If exactly one scheme is found, I auto-fill it.
- If multiple schemes are found, I present a numbered list and you reply
  with the number or the scheme name.
- If `xcodebuild -list` exits non-zero (no Xcode project at the target
  root), I skip the entire Apple sub-flow with a single-line note.

From `xcrun simctl list devices available`:
- If at least one simulator is found, I pick the most recent iOS simulator
  by default (reply `edit` to override).
- If no simulators are found and this is a macOS project, I use
  `platform=macOS`.
- Otherwise I ask you for a destination string.

#### 7.2.2 Script and settings edits (Form E, G7-edit)

For each of the four targets — `scripts/validate-swift.sh`,
`scripts/test-swift.sh`, `.claude/settings.json` (env block), and
`scripts/format-swift.sh` (SWIFT_SOURCE_DIRS for non-SPM layouts only) — I
render a Form E:

```
PROPOSED EDIT — scripts/validate-swift.sh
  Discovered values:
    XCODE_SCHEME       = "MyApp"        (from xcodebuild -list)
    XCODE_DESTINATION  = "platform=iOS Simulator,name=iPhone 16,OS=latest"
                                        (from xcrun simctl list devices available)

  Diff:
    -XCODE_SCHEME=""
    +XCODE_SCHEME="MyApp"
    -XCODE_DESTINATION=""
    +XCODE_DESTINATION="platform=iOS Simulator,name=iPhone 16,OS=latest"

Reply: `yes` to apply · `edit` to provide your own values
       · `skip` to leave the file unchanged · `abort` to stop
```

**Anchor-matching rules:**

- Primary: literal `XCODE_SCHEME=""` / `XCODE_DESTINATION=""` match.
- Legacy fallback: `XCODE_SCHEME="[SCHEME_NAME]"` /
  `XCODE_DESTINATION="[DESTINATION]"`.
- Already-populated or unknown: emit a one-line
  `note: <file> <variable> is already set to "<current_value>" — skipping`
  and move on; do not propose overwrite.

`.claude/settings.json` edit uses JSON parse-mutate-serialize (never
regex). If the file fails to parse, I emit a diagnostic with the intended
diff as textual instructions and ask you to apply it manually.

#### 7.2.3 swift-format install (Form I, G7-install)

```
PROPOSED ACTION — install
  Command:        brew install swift-format
  Purpose:        enables scripts/format-swift.sh to format Swift sources
  Pack-tested:    swift-format ≥510.0.0 (see supporting-docs/DEPENDENCIES.md;
                  pack-tested starting range 2026-04, refine empirically
                  per PACK-FEEDBACK.md Part 10)
  Side effects:   writes to /opt/homebrew/Cellar; ~5MB; network required
  Skip impact:    format-swift.sh emits a warning but does not block validation

Reply: `yes` to install · `skip` to leave uninstalled · `abort` to stop
```

Idempotency: if `command -v swift-format` already returns a path AND
`swift-format --version` is within the known-good range, I emit a one-line
`note: swift-format already installed at <version> (within known-good range) — skipping`
and do not render Form I.

The single-line `note:` is rendered inside the Form R results table
per § 7.6 (Preview rendering) — it is not a separate Form rendering.

#### 7.2.4 Xcode companion files (Form M, G7-machine)

```
PROPOSED ACTION — install Xcode companion files (machine-level)
  Target:       ~/Library/Developer/Xcode/CodingAssistant/
  Source:       $PACK/xcode-companion-templates/
  Files (from `ls "$PACK/xcode-companion-templates/"` at run time;
         falls back to the hardcoded four-file list if `ls` fails):
    1. ClaudeAgentConfig/CLAUDE.md          (replaces if present)
    2. ClaudeAgentConfig/settings.json      (replaces if present)
    3. codex/AGENTS.md                       (replaces if present)
    4. codex/config.toml                     (replaces if present)
  Side effects: writes to your home directory; one-time per Mac

Reply: `yes` to install all · `skip` to leave companion files alone
       · `abort` to stop
```

Idempotency: I run `cmp -s` between each source and its target; if every
pair is byte-identical, I emit a one-line
`note: Xcode companion files already present and up to date — skipping`
and do not render Form M. If all files are present but some differ, I
render Form M with a recommendation line
`recommendation: installed companion files differ from the pack — reinstall recommended`
— default remains `skip`.

The single-line `note:` is rendered inside the Form R results table
per § 7.6 (Preview rendering) — it is not a separate Form rendering.

### 7.3 K3 — gRPC sub-flow

Runs only if `[TRANSPORT]` includes gRPC, or a `proto/` directory
exists at the project root. Otherwise skipped.

#### 7.3.1 Apple-side gRPC tooling (Form I, G7-install)

One Form I per tool, using the shape in §7.2.3:

- `brew install bufbuild/buf/buf` — Pack-tested: buf ≥1.35.0.
- `brew install swift-protobuf` — Pack-tested: swift-protobuf ≥1.28.0.
- `brew install grpc-swift` — Pack-tested: grpc-swift ≥1.24.0 (1.x-line;
  2.x migration is out of scope for v10.0).

Each Form I applies the idempotency rule from §7.2.3 — already-installed
and in-range tools are skipped with a note.

The note is rendered inside Form R per § 7.6 (Preview rendering).

#### 7.3.2 Python-side gRPC tooling (Form I, G7-install)

Runs only if Python is also detected. One Form I per package, using
`uv add` instead of `brew install`:

- `uv add grpcio-tools` — Pack-tested: grpcio-tools ≥1.64.0.
- `uv add grpcio` — Pack-tested: grpcio ≥1.64.0.
- `uv add grpcio-status` — Pack-tested: grpcio-status ≥1.64.0.
- `uv add grpcio-reflection` — Pack-tested: grpcio-reflection ≥1.64.0
  (optional, only if reflection is used).

Each Form I in this section applies the § 7.2.3 idempotency rule;
the resulting note is rendered inside Form R per § 7.6
(Preview rendering).

#### 7.3.3 Proto code generation example

Once the tooling is in place, generate the first proto outputs:

```bash
./scripts/proto-gen.sh
```

The PM chat does not run this command as part of kickoff (it requires
a `.proto` definition file and project-specific configuration); it
prints the invocation so the developer can run it after kickoff
completes.

### 7.4 Behavior on failure / ambiguity

Common discipline across all branches:

- **Never silently skip.** Every condition that does not produce the
  ideal outcome is named in the reply.
- **Never block the entire kickoff on a single failure.** The
  developer can complete the rest of the kickoff and re-attempt the
  failing step later.
- **Always print the command that was run and its observed output**
  before drawing a conclusion. The developer can override.

Specific behaviors:

1. **Xcode not installed** — `xcodebuild -list` exits non-zero, or
   `[PLATFORM_TARGETS]` indicates a non-Apple project. Skip the Apple
   sub-flow with a single line: `No Xcode detected — skipping Apple-only steps.`
2. **One scheme detected** — auto-fill; surface in the Form E prompt.
   `Scheme "MyApp" (only one found) — used as XCODE_SCHEME.`
3. **Multiple schemes detected** — present a numbered list:
   `Schemes found:  1. MyApp  2. MyAppTests … Reply with the number or the scheme name.`
4. **No simulators available** — if macOS project, fall back to
   `XCODE_DESTINATION="platform=macOS"`. Otherwise ask: `No simulators available. Reply with a destination string or say `diagnose` to inspect available runtimes.`
5. **`brew` not installed** — do not attempt installs. Print:
   `Homebrew not installed. Install from https://brew.sh and re-run kickoff.`
6. **Required brew tool missing** — propose `brew install <pkg>` via
   Form I. On `skip`, record the skip and proceed.
7. **Brew tool at out-of-range version** — propose `brew upgrade <pkg>`
   via Form I (upgrade variant). On `skip`, keep current version.
8. **Source layout indeterminate** (both `Sources/` and a non-standard
   directory contain Swift sources) — ask once: `Both `Sources/` and `MyApp/` contain Swift sources. Reply with the directories `format-swift.sh` should target (space-separated), or `default` to leave SWIFT_SOURCE_DIRS="".`
9. **Network required but unavailable** (`brew install` fails with a
   network error signature) — do not retry. Print the failed command and
   the stderr tail; treat the install as `skip`-by-failure; proceed.

### 7.5 Reply grammar

- `yes` / `y` — proceed.
- `no` / `skip` — do not proceed; record the skip.
- `abort` — exit kickoff entirely.
- `edit` (Form E only) — provide overriding values in the next message.
- Bare integer or scheme name (multi-scheme) / destination string
  (no-simulator) / space-separated directory list (source-layout).
- Empty / unrecognized / "no" / "don't" / "wait" → treated as `no`;
  re-prompt with a clarifying question. Never defaults to `yes`.

### 7.6 Idempotency rules

Procedure 7 is idempotent on re-invocation. Each Form has a
target-state definition; when the target state already holds, the
Form emits a single-line `note:` diagnostic and moves on without
re-rendering.

- **Form R** — always runs (no target state; read-only discovery).
- **Form I** — skip when `command -v <tool>` returns a path AND
  `<tool> --version` is within the pack-tested range.
- **Form E** — skip when the anchor matches the proposed value
  (empty diff) or when the file's variable is already set to a
  non-placeholder value (see §7.2.2 anchor-matching rules).
- **Form M** — skip when every source/target pair is byte-identical
  under `cmp -s`.

**Preview rendering.** When a Form's idempotency rule fires (Form I:
`command -v <tool>` returns a path AND `<tool> --version` is within
the pack-tested range; Form M: every source/target pair is
byte-identical under `cmp -s`), the gate renders as a single-line
`note:` diagnostic inside the Form R results table rather than as a
separately-rendered Form. The preview is the gate — there is no
proposed action for the developer to approve, skip, or abort. This
applies wherever Form I or Form M is invoked (§ 7.2.3 swift-format,
§ 7.2.4 Xcode companion files, § 7.3.1 Apple-side gRPC tooling,
§ 7.3.2 Python-side gRPC tooling). The full Form renders only when
the idempotency rule does NOT fire — i.e., when there is something
to gate. Reply grammar (§ 7.5) does not apply to preview lines; they
are informational notes inside Form R, whose own reply grammar
covers the read-only discovery decision.

For concurrent / interrupted kickoff handling, see
`project-template/docs/pack/PM-CHAT.md` § Before starting a new
project ("Never run two PM chats simultaneously for the same
project").

If Form R runs, all Form I targets are in-range, all Form E anchors
are populated, and all Form M targets are byte-identical, Procedure 7
prints: `Kickoff complete — nothing to change.` This is the empty-diff
re-invocation terminal state.

### 7.7 Artifacts and cross-references

**Artifacts modified:** `scripts/validate-swift.sh`,
`scripts/test-swift.sh`, `scripts/format-swift.sh` (conditional on
non-SPM layout), `.claude/settings.json` (env block), and
`~/Library/Developer/Xcode/CodingAssistant/{ClaudeAgentConfig,codex}/*`
(machine-level; not in the project tree).

**Artifacts never touched by Procedure 7:** `BACKLOG.md`; `STATUS.md`;
`CHANGELOG.md`; `ARCHITECTURE.md`; `IMPLEMENTATION-PLAN.md`; the
trinity files (`CLAUDE.md`, `AGENTS.md`, `GEMINI.md`); `.codex/`,
`.gemini/`, `.claude/agents/` subtrees; any file under `docs/project/`
other than the ones the PM chat ordinarily writes; any `x-` custom
agent / skill / prompt file.

**Sub-flow conditions:** the Apple sub-flow runs iff `[PLATFORM_TARGETS]`
includes any of iOS, iPadOS, macOS, tvOS, watchOS, or visionOS; the
gRPC sub-flow runs iff `[TRANSPORT]` includes gRPC or a `proto/`
directory exists at the project root; the Python Form I quadruplet
under §7.3.2 runs iff Python is also detected.

The kickoff-variant continuation pointer in
`project-template/docs/pack/prompts/pm-chat.md` Variant: kickoff is
the invocation point for Procedure 7.
