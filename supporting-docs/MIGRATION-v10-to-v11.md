# Migrating from v10 to v11

This guide is the authoritative narrative for upgrading an existing
**v10**-pack-configured project to **v11**. Migration is complete after
Phase A; Phase B (tracker opt-in) is DEFERRED.

1. **Phase A — forced v10→v11 changes.** Everyone runs this. Trinity
   refresh, HELP-FRAGMENT install, per-CLI `pack-help` surfaces, issue
   templates, legacy doc relocation tail. Driven by
   `scripts/migrate-v10-to-v11.sh`. (`tracker.toml.example` is
   NO LONGER installed — see Phase B.)
2. **Phase B (tracker opt-in) — DEFERRED.** Tracker integration is
   deferred indefinitely (no release version); flat-file
   per-entry is the sole supported mode. The ability to flip to tracker
   mode is blocked and the tracker code is retained dormant for a future
   resumption — there is no `pack tracker init` opt-in to run. Migration
   is Phase-A complete without it.

If you're on **v9.x or earlier**, the v9->v10 migrator was sunset
in v11; v9 is no longer supported. Reach out to the pack
maintainer for migration guidance, or recover the legacy migrator
from history with
`git -C "$PACK" checkout v10 -- scripts/migrate-v9-to-v10.sh
supporting-docs/MIGRATION-v9-to-v10.md`.

If you're managing **multiple projects**, repeat the whole flow per
project — there is no shared state between projects.

---

## What changed in v11

**Forced (Phase A):**

- Gemini CLI support is replaced by **Antigravity CLI** (`agy`). The
  16 pack agents install as an Antigravity plugin bundle at
  `.agents-plugin/optiquity-agents/`; loose skills install at
  `.agents/skills/`; the Antigravity MCP surface is
  `.agents/mcp_config.json`. Your custom (`x-`) agents are auto-lifted
  into the bundle and your old `.gemini/` tree is retired to a
  `gemini-retired-docs/` backup. See "Gemini → Antigravity transition"
  below for the full narrative.
- New help-verb system: `pack help` (LCD shell verb) and `/pack-help`
  (per-CLI command). Both invoke `scripts/pack-help.sh` which renders
  `HELP-FRAGMENT-PACK.md` (pack repo) or `docs/pack/HELP-FRAGMENT.md`
  (client repo).
- New trinity addenda: `## Quick reference` block at the top of every
  trinity file (pack-root + client) — one line for `pack help` /
  `/pack-help`, one line for `pack-startup` / `pm-startup` recommended
  first action.
- Customization-preservation contract: `init-project.sh --update`
  and `migrate-v10-to-v11.sh` share one library and one truthful
  report format. See `MERGE-STRATEGY.md` for the per-file class matrix.
- Legacy doc relocation tail: any v9-era reference docs still at project
  root (`METHODOLOGY.md`, `PROMPT-TEMPLATES.md`, etc.) are moved to
  `docs/pack/` (with `git mv` when tracked, sidecared otherwise).
- Issue template forms (`.github/ISSUE_TEMPLATE/work-item.yml`,
  `inbound.yml`, `config.yml`) installed (the `inbound.yml` flat-file
  feedback channel is live; the work-item form is a dormant baseline).
- `tracker.toml.example` is NO LONGER installed at project root —
  tracker integration is deferred. The dormant config record
  stays committed pack-side at
  `project-template/tracker.toml.project-example`.

**Phase B (DEFERRED):**

The tracker feature below is deferred indefinitely and its code is
retained DORMANT and test-covered for a future resumption. None of it
is reachable in v11.0 — flat-file per-entry is the sole supported mode.

- TrackerProvider abstraction (V1 §2.1): 18 ops + raw + capabilities,
  one canonical implementation against `gh`. Future backends
  (forgejo / linear / jira) plug in without touching callers.
- Forward migration `BACKLOG.md` → GitHub Issues (V1 §6.2),
  reverse migration GitHub Issues → `BACKLOG.md` sidecar (V1 §6.5).
  Both idempotent.
- Inflection-point recommendation system (D-19): the recommendation is
  deferred — startup surfaces no tracker opt-in.
- TrackerProvider abstraction consumed by PM chat / Pack chat for
  tracker-aware prompts (dormant).

**Out of scope for this version:**

- Multi-tracker (Linear / Jira / Forgejo) backends — the abstraction
  exists, only `gh` is implemented in v11.
- `--dry-run` / `--apply` / `--resume` migrator modes — shipped in
  v11.0. Bare invocation defaults to `--apply` and
  auto-runs `--dry-run` first if no fresh dry-run output exists, so
  the single-shot UX is preserved. See `MERGE-STRATEGY.md` §A1 for
  full mode semantics.

---

## Gemini → Antigravity transition

v11 replaces the pack's Gemini CLI leg with **Antigravity CLI**
(`agy`). The migrator handles the transition automatically — you do
not re-create anything by hand. What changes on disk:

- **Pack agents become the Antigravity bundle.** The 16 pack agents
  install as an Antigravity plugin bundle at
  `.agents-plugin/optiquity-agents/` (a `plugin.json` manifest plus
  `agents/*.md` role templates and a `RUNTIME-SUBAGENT-PATTERN.md`
  fallback). Bundle agents install **replace-if-different**: a pack
  agent that changed between versions is refreshed; a bundle agent you
  customized in place is preserved (or sidecared if both you and the
  pack changed it).
- **Your custom (`x-`) agents are auto-lifted into the bundle (S5a).**
  Each custom agent under your old `.gemini/agents/x-*.md` is copied
  into `.agents-plugin/optiquity-agents/agents/` and becomes a live
  Antigravity agent. A same-named bundle custom is never overwritten.
- **The departing `.gemini/` tree is retired as a backup (S5b).** Your
  whole `.gemini/` directory is moved (never deleted) into a
  root-level `gemini-retired-docs/` holding directory as a recovery
  copy. The originals also remain in your project's git history. If
  `gemini-retired-docs/` trips your CI, add it to your `.gitignore`.
- **Skills land at `.agents/skills/`.** Antigravity reads loose skills
  from `.agents/skills/<name>/SKILL.md`; the pack distributes them
  there alongside the `.claude/` and `.codex/` copies.
- **MCP config moves to `.agents/mcp_config.json`.** The Antigravity
  MCP surface ships as `.agents/mcp_config.json.example`; copy it to
  the live `.agents/mcp_config.json` (gitignored) if you use MCP
  servers under Antigravity.

### Post-migration surface — Antigravity

After migration, a v11 project carries these Antigravity surfaces:

- `.agents-plugin/optiquity-agents/` — the agent plugin bundle
  (`plugin.json` + `agents/*.md` + `RUNTIME-SUBAGENT-PATTERN.md`),
  including any custom (`x-`) agents lifted from your old `.gemini/`.
- `.agents/skills/<name>/SKILL.md` — loose Antigravity skills.
- `.agents/mcp_config.json` (from `.agents/mcp_config.json.example`) —
  the Antigravity MCP surface.
- `gemini-retired-docs/` — the backup copy of your departing `.gemini/`
  tree (recovery convenience, not a tracked deliverable).

Install the Antigravity agent bundle once so the roster is available
to every session:

```sh
agy plugin install ./.agents-plugin/optiquity-agents
```

<!-- RE-VERIFY at impl: agy plugin install runtime re-read semantics (does Antigravity re-read the bundle after the migrator updates agents/*.md in place, or require a re-install?), antigravity.google/docs -->

Invoke any agent via `./agent-run.sh agy --agent <name>` — the same
command format used for Claude and Codex.

---

## Skill model changes

v11 reframes how `docs/pack/PLATFORM-SKILLS.md` describes skill
selection. The reframe is a **behavioral change**, not a doc-only
change — see "Behavioral impact" below.

### What changed

- **5 dimensions, not 4.** v10's four dimensions (Platform Targets,
  Languages, Component Roles, Communication Protocols) are reframed
  as five: D1 (runtime / OS substrate), D2 (cross-platform languages),
  D3 (component role / app-layer), D4 (communication protocols), and
  D5 (deployment surface — new).
- **Three load mechanisms made explicit.** Skills now load through
  three orthogonal mechanisms: Tier 0 base skills (loaded for every
  project, every relevant agent), intersection-cell skills (loaded
  when a specific D1–D5 cell predicate matches — e.g.,
  `python-server-architecture` loads when `D2=python ∩ D3=server`),
  and trigger-loaded skills (loaded by agent role rather than project
  shape — e.g., `audit-methodology` loads for every auditor invocation
  regardless of project type).
- **"Tier 1 / Tier 2" nomenclature retired.** The pre-v11 framing
  bucketed skills into "Tier 1 role" and "Tier 2 platform"; v11
  replaces this with **Tier 0 base / dimensional / intersection /
  trigger**. Several skills (`security-patterns`, `api-design`,
  `debugging`, `ui-test-strategy`) that were classified as "Tier 1
  role" in v10 are reclassified as Tier 0 base because their content
  is universal methodology, not role-specific.
- **No SKILL.md content changed.** The reframe is a documentation
  and selection-model change. Every `project-template/skills/*/SKILL.md`
  file ships byte-equivalent to its v10 form (modulo the unrelated
  Python skill split handled by Stage S5b of the migrator — see
  "Migrator handling" below).

For the authoritative v11 dimension tables, the Tier 0 base list, the
sparse intersection table, and the trigger-loaded list, read
`docs/pack/PLATFORM-SKILLS.md` after migration completes.

### Behavioral impact

The reframe is a pack-product change masquerading as a doc
change: PLATFORM-SKILLS.md edits affect every consuming PM chat
session because every PM chat re-reads PLATFORM-SKILLS.md when it
generates a prompt (per the file's own header instruction). **Actual
impact on running PM chats is minimal** — PM chats do not cache
PLATFORM-SKILLS.md across prompts; the next prompt after migration
picks up the v11 tables automatically. Agents do not cache the file
either. **What client projects must do:**

1. **No manual file edit needed for the reframe itself.** The PM
   chat re-reads `docs/pack/PLATFORM-SKILLS.md` on its next prompt
   and adopts the v11 model transparently. The migrator overwrites
   `docs/pack/PLATFORM-SKILLS.md` with the v11 template (the file
   ships from the pack, not project-customized).
2. **Re-apply locally edited PLATFORM-SKILLS.md customizations
   manually.** Per architecture §7.6, if you have locally edited
   `docs/pack/PLATFORM-SKILLS.md` (rare but possible — e.g.,
   handwritten changes to the dimension tables or the worked
   examples), the v10 → v11 reshape will not preserve those edits
   automatically. The four-dimension table is replaced wholesale by
   five-dimension tables; the row order, column structure, and
   section organization differ. The migrator writes the new template
   and saves your pre-migration copy as
   `docs/pack/PLATFORM-SKILLS.md.v10-customized` (per the
   customization-preserve sidecar contract documented in
   `MERGE-STRATEGY.md`); reconcile
   manually as Step 2 above directs.
3. **`## Custom agents` and `## Custom skills` sections are
   preserved byte-identical.** These two H2 sections at the bottom
   of `docs/pack/PLATFORM-SKILLS.md` are project-owned and
   preserved by the customization-preserve sidecar mechanism
   regardless of the reframe (see `MERGE-STRATEGY.md` per-file
   matrix entry for PLATFORM-SKILLS.md). The reframe does not
   touch their content.
4. **Custom agents column header rename.**
   The illustrative row column headers in the `## Custom agents`
   section were `Tier 1 skills | Tier 2 skills` in v10 and are
   `Base skills | Dimensional skills` in v11 (semantics unchanged
   — Tier 1 → Base, Tier 2 → Dimensional). For client projects
   that already populated real custom-agent rows under the
   deprecated headers, the customization-preserve sidecar mechanism
   preserves the project's section verbatim (including the deprecated
   headers)
   — the migrator does NOT rewrite the headers automatically. To
   adopt the v11 convention, manually rename the two columns in
   your live `docs/pack/PLATFORM-SKILLS.md` after migration:
   `Tier 1 skills` → `Base skills`, `Tier 2 skills` → `Dimensional
   skills`. The data in those columns stays put. Future Procedure
   5.1 invocations (creating a new custom agent) emit the v11
   headers — see `INSTALL-PROCEDURES.md` § "Procedure 5.1 step 4"
   for the documented column convention.

### Migrator handling

The dimension reframe itself requires no migrator-script work
because the reshape is doc-only at the pack level — the migrator
ships the v11 PLATFORM-SKILLS.md template and the
customization-preserve mechanism preserves project customizations
under the per-class strategy in
`MERGE-STRATEGY.md`.

The one skill *rename* in v11 — the Python split
(`python-architecture` → `python-server-architecture` +
`python-data-architecture`) — is handled by migrator Stage S5b,
which writes a `*.v10-customized` advisory listing the old
references and the disambiguation guidance. S5b ships independently
of the dimension reframe. See `scripts/migrate-v10-to-v11.sh` for
the implementation.

### Trinity-marker non-overlap

The dimension reframe and the trinity-marker preservation mechanism
are **non-overlapping**: the trinity-marker mechanism introduces
Shape A / Shape B markers and a `renamed-from` annotation to
preserve project-owned sections in the trinity files (`CLAUDE.md`,
`AGENTS.md`, `GEMINI.md`) at project root. The PLATFORM-SKILLS.md
reframe does NOT touch the trinity files (PLATFORM-SKILLS.md lives
at `docs/pack/`, not at project root) and does NOT use the trinity-
marker mechanism.

The trinity files' `## Skill loading` H2 section was updated in v11
to describe the 5+3 model and to point at PLATFORM-SKILLS.md
as the authoritative reference; the trinity rule applies (the same
edit lands in CLAUDE.md, AGENTS.md, and GEMINI.md). The
`**Active skills:**` line format inside that section did NOT change
between v10 and v11 — it stays a comma-separated skill-name list
written by the PM chat at project kickoff. Skill **names** in that
list change only for the Python split case (handled by S5b
advisory); the dimension reframe itself produces no `Active skills`
edits.

The two mechanisms — PLATFORM-SKILLS.md customization-preservation
(sidecar-based) and trinity-marker preservation (in-line marker-
based) — operate on different file sets via different surfaces
(Shape A pack-canonical sections vs Shape B project-owned override
sections in the trinity, vs `## Custom *` sections in
PLATFORM-SKILLS.md). The non-overlap is intentional; they do not
conflict.

### D5 monorepo gotcha

A monorepo with both an Apple app and a Linux container
backend selects D5 = {`apple-distribution`, `linux-container`} and
loads BOTH `deployment-apple` AND `deployment-python` globally for
every prompt the PM chat generates. The deployment skills then apply
*to the right component* via per-component scoping in the agent
prompt — `deployment-apple` is not relevant to the backend's
containerization, and `deployment-python` is not relevant to the
Apple app's notarization.

The current loader model loads both skills globally and trusts the
agent prompt (constructed by the PM chat) to scope correctly. This
is the documented v11 behavior; per-component fine-grained loading
is not in v11 scope. The same gotcha is documented in
`docs/pack/PLATFORM-SKILLS.md` § "Monorepo D5 scoping note".
Multi-component (monorepo) projects migrating from v10 should
verify that PM-chat prompt construction continues to scope
deployment-skill rule citations to the relevant component.

---

## Per-entry decomposition

v11 introduces a per-entry source-of-truth tree for the three
high-churn project documents: `BACKLOG.md`, `IMPLEMENTATION-PLAN.md`,
and `CHANGELOG.md`. Each becomes a per-entry tree under
`docs/project/backlog/`, `docs/project/implementation-plan/`, and
`docs/project/changelog/` respectively. The pre-existing monolithic
files become regenerated mirrors of the per-entry trees, not the
source of truth.

### What changes

- **New directories.** `docs/project/backlog/`,
  `docs/project/implementation-plan/`, and `docs/project/changelog/`
  appear after migration, each containing:
  - One Markdown file per entry (e.g., `docs/project/backlog/TD-NNN.md`,
    `docs/project/implementation-plan/phase-N.md`,
    `docs/project/changelog/YYYY-MM-DD-<slug>.md`) — authored source
    of truth.
  - `_rules.md` — the per-stream contract (what an entry contains,
    how it's named, when it's regenerated). Read this before any
    per-entry edit.
  - `_intro.md` — the preamble extracted from the v10 monolithic
    file (lines 1–20 of the source on first migration); re-emitted at
    the top of the regenerated mirror.
  - `_format.md` (changelog only) — the changelog entry shape contract.
  - `_toc.md` — a derived table of contents for the stream.
- **Monolithic files become regenerated mirrors.** `docs/project/BACKLOG.md`,
  `docs/project/IMPLEMENTATION-PLAN.md`, and `docs/project/CHANGELOG.md`
  remain on disk for read convenience and for tools that have not
  yet been updated to read the per-entry tree directly. They are
  rewritten from the per-entry tree on every regeneration; hand
  edits to the mirror are not preserved across regeneration.
- **CI gates the invariant.** `validate-pack.py` Check 32 (mirror-in-sync)
  and Check 33 (TOC-in-sync) FAIL in CI on any committed divergence
  between the per-entry tree and its mirror or TOC.

### Why mandatory and non-reversible

Per-entry decomposition is mandatory under the v10 → v11 migration
and is non-reversible — once the per-entry tree exists, the
monolithic file is a derived artifact. There is no `--skip-decompose`
option and no rollback verb that re-collapses the per-entry tree
into a monolithic source-of-truth file. Per-version monolithic
sources are a v10-era pattern; v11 retires it.

### What the user does

Nothing. The v10 → v11 migrator handles decomposition automatically.
A new sub-operation (`_v10_to_v11_decompose_streams`) inside the
migrator's post-dispatch hook reads each v11-shape monolithic file
and emits the per-entry tree plus the regenerated mirror. The
sub-operation runs after all monolithic-content mutations have
settled (rename, relocation, install, capability-token translation)
so the source content is final before decomposition.

### Backup and rollback

The pre-migration backup at `.pack-migrate-v10-to-v11-backup/`
(written by Stage S1) is unchanged by per-entry decomposition. The
rollback recipe in § Rollback below restores both the v10
monolithic files and any pre-migration state by rsyncing the backup
back over the working tree — exactly as it did before per-entry
decomposition. The per-entry tree directories are removed by the
rsync `--delete` step since they are not present in the v10 backup.

If the migration was committed and you want to revert without
losing post-migration work, `git revert HEAD` reverts the
migration commit including the per-entry-tree introduction;
post-migration commits can then be cherry-picked back as needed.

### `--force-overwrite-mirror` flag (advanced)

If you hand-edit `docs/project/BACKLOG.md` (or any other mirror)
after migration and then run the migrator or regenerator again,
the apply-phase blocks with a non-zero exit and tells you the
mirror diverges from the per-entry tree. Two recovery paths:

- **Recommended:** re-apply your hand edit to the corresponding
  per-entry file under `docs/project/backlog/<ID>.md`, then
  re-run the migrator. The regenerator will emit a mirror that
  matches the per-entry tree and contains your edit.
- **Advanced override:** pass `--force-overwrite-mirror` to
  acknowledge that the hand-edited mirror will be overwritten.
  Sample:
  ```sh
  bash scripts/migrate-v10-to-v11.sh --apply --force-overwrite-mirror
  ```
  Use this only when you have already captured your hand edit
  elsewhere (e.g., applied it to the per-entry tree).

A future opt-in client-side pre-commit hook (deferred to v11.x per
`ARCHITECTURE-PER-ENTRY-SPLIT-INTEGRATION-ADDENDUM.md` §5.6) is
planned to inherit these same block-and-flag semantics; that work is
tracked separately and is not part of the v11.0 ship surface. Until
then, divergence is caught at CI time via `validate-pack.py` Check 32
(mirror-in-sync) and Check 33 (TOC-in-sync), and the
`--force-overwrite-mirror` recovery flag described above is available
for advanced users to acknowledge intentional overwrites. See
`MERGE-STRATEGY.md` § "12. `generic` — everything else" for the
mirror-vs-source treatment in the customization-preserve pipeline.

---

## Before you start

1. **Commit or stash.** The migrator refuses a dirty working tree.
2. **Verify v10 baseline.** Your project must be currently
   v10-configured (`CLAUDE.md` and `.claude/` present at project root).
   The migrator exits with rc=13 otherwise.
3. **Set `PACK`.** The pack repo must be on disk and at v11+ tag:
   ```sh
   export PACK=/path/to/pack-repo
   git -C "$PACK" describe --tags
   # → v11.0 (or later)
   ```
4. **Understand sidecar conventions.** Files where the migrator can't
   safely auto-merge get a `.v10-customized` sidecar of your pre-migration
   copy. You reconcile manually after the migrator finishes. See
   `MERGE-STRATEGY.md` for which classes can produce sidecars.
5. **Pre-clean stale `--update` artifacts.** If you previously ran
   `init-project.sh --update`, remove any `*.pre-update` sidecars
   first — the v10→v11 migrator and `--update` use different sidecar
   suffixes but it's cleaner to start from a known state.
6. **(Optional but recommended) Preview the migration first.** Run
   `scripts/dry-run-migration.sh /path/to/your/v10/clone` from the
   pack repo to see exactly what files Step 1 below would change,
   without modifying anything. The dry-run renders a Markdown report
   showing the file-tree diff and any sidecars the real migration
   would write. See `DRY-RUN-MIGRATION.md` for the full input
   contract, output interpretation, and CI release-gate pattern.

---

## Step 1 — Run the migration script

```sh
PACK=/path/to/pack-repo bash scripts/migrate-v10-to-v11.sh
```

Default target is the current directory; pass an explicit path as the
last argument if needed.

The script runs 7 framework stages (S0..S6). Stage S4 is split into two
sub-banners (`S4a` and `S4b`) and stage S5 into three (`S5`, `S5a`,
`S5b`) for operator clarity — each split pair runs inside the
framework's single parent stage and shares that stage's sentinel and
framework exit code (`24` for S4; `25` for S5).

| Stage | What it does |
|---|---|
| S0 | Pre-flight (pack valid, customization-preserve lib present, target git, clean tree, v10-shaped, v10 tag resolves) |
| S1 | Backup — full working tree (excludes `.git/` + state dirs) into `.pack-migrate-v10-to-v11-backup/` |
| S2 | Initialize customization-preserve state |
| S3 | Dispatch v10 → v11 changes via the customization-preserve engine (trinity / configs / scripts / agents / docs) |
| S4a | rename `IMPLEMENTATION_PLAN.md` → `IMPLEMENTATION-PLAN.md` at project root. History-preserving via `git mv` for tracked source; plain `mv` fallback for untracked. No-op if the source is absent. Halts with the typed error `migration-rename-collision` if both names already exist (the user inspects, resolves, re-runs). |
| S4b | relocation tail (legacy root docs → `docs/pack/`) |
| S5 | Install v11 client artifacts (HELP-FRAGMENT*.md, issue forms, per-CLI pack-help to `.claude`/`.codex`/`.agents`, the Antigravity agent plugin bundle at `.agents-plugin/optiquity-agents/` installed replace-if-different). `tracker.toml.example` is NO LONGER installed — tracker integration is deferred; the dormant config record stays committed pack-side at `project-template/tracker.toml.project-example`. |
| S5a | Lift each departing Gemini custom (`x-`) agent into the Antigravity bundle (`.agents-plugin/optiquity-agents/agents/`) so it becomes a live Antigravity agent — never overwriting a same-named bundle custom. |
| S5b | Retire the departing `.gemini/` tree by moving it (never deleting) into a root-level `gemini-retired-docs/` backup holding directory. |
| S6 | Render truthful migration report at `.pack-migrate-v10-to-v11/report.md` |

**Exit codes:**

| Code | Meaning | What to do |
|---|---|---|
| 0 | Success | Continue to Step 2. |
| 10 | `$PACK` invalid | Set `PACK` to a valid pack repo path. |
| 11 | Target is not a git repo | `git init` the target first. |
| 12 | Working tree dirty | `git stash` or commit. |
| 13 | Target does not appear to be a pack-configured project (no `CLAUDE.md` or no `.claude/`) | For a fresh install use `init-project.sh`. (v9.x is no longer supported — the v9->v10 migrator was sunset in v11; reach out for migration guidance.) |
| 14 | v10 baseline tag missing in pack repo | `git -C "$PACK" fetch --tags` then retry. |
| 15 | Customization-preserve library missing under pack | The pack repo is corrupt or incomplete; re-clone. |
| 21–30 | Stage `S<n>` failure | Read the printed error message; address; retry. |
| 31 | `EXIT_GATE_FAILED` — verification gate (Gate 1, 2, or 3) reported a defect | Read the printed `[FAIL]` lines and the gate's printed recovery banner. Gate 1 (during `--dry-run`) is read-only — fix the underlying defect and re-run `--dry-run`. Gate 2 (post-Phase-A) requires restoring the working tree from `.pack-migrate-v10-to-v11-backup/` via the rsync recipe in §Rollback below + re-run of `--dry-run` + `--apply`; fix-and-continue is NOT supported because S4/S5/S6 sentinels are already marked `.done`. (The legacy `scripts/restore-from-backup.sh` is for v9.3→v10 backups and does NOT apply to v10→v11.) Gate 3 (post-Phase-B, tracker-mode only) is recoverable without restoring from backup — run `pack tracker doctor` and follow the printed verbs. See `MERGE-STRATEGY.md` §A1 for full gate semantics. |

**Verification gates.** During `--dry-run` and `--apply` the
migrator emits one or more `── Gate N — ... ──` banners. There are
three gates:

- **Gate 1** fires inside `--dry-run` and validates the dispositions
  TSV / report.md before the user reviews them. Read-only.
- **Gate 2** fires after Phase-A completes inside `--apply` (post-S6).
  It checks trinity addenda, HELP-FRAGMENT byte-equality, dispositions
  consistency, relocated docs, and `validate-pack`. On FAIL the
  migrator exits `31` (`EXIT_GATE_FAILED`).
- **Gate 3** fires after Phase-B inside `--apply`, **only** when
  `tracker.toml` is present at the target with `mode.state =
  "tracker"` and `migration.forward_complete = true`. In flat-file
  mode the gate prints `[INFO] tracker: skipped` and returns 0.

A FAIL banner always lists the failing checks as `[FAIL] <check-name>`
lines and prints a recovery banner naming the supported recovery path
for that gate. See `MERGE-STRATEGY.md` §A1 for the full gate
semantics + recovery contracts.

---

## Step 2 — Review the migration report

```sh
less .pack-migrate-v10-to-v11/report.md
```

The report is **truthful** (per the migrator contract): every file the
migrator processed appears in exactly one section. No silent drops.

Sections you may see:

- **Files updated to new pack version** (`pack-update-applied`) — pack
  changes adopted; you had no customizations on these files. No action
  needed.
- **Files merged (project customizations preserved)**
  (`merged-with-customization`) — pack changes adopted AND your edits
  preserved. No action needed; `git diff` to confirm.
- **Files needing manual reconciliation**
  (`customization-detected-needs-reconciliation`) — both you and the
  pack edited these files; the migrator wrote the new pack template
  to the live file and saved your pre-migration copy as a
  `<file>.v10-customized` sidecar. **You resolve.**
- **Files retired by pack** (`removed-by-design`) — file no longer
  ships in v11. If you'd customized it, your pre-migration copy is
  in a sidecar.
- **Project-only files** — your custom files; untouched.
- **Files you removed** — honored; pack kept its copy of any pack-
  shipped file you'd previously deleted.
- **Unchanged files** — byte-equal across baseline / your tree / new
  pack. No action.

For every `Files needing manual reconciliation` row:

1. Open the destination file (e.g., `CLAUDE.md`) — it now has the v11
   template.
2. Open the sidecar (`CLAUDE.md.v10-customized`) — your pre-migration
   content.
3. Open the structured diff at
   `.pack-migrate-v10-to-v11/diffs/CLAUDE.md.three-way.diff`. The diff
   shows BASE→OURS (your edits since v10) and BASE→THEIRS (pack edits
   v10→v11) separately.
4. Manually merge your customizations into the new template.
5. `rm` the sidecar.
6. `git add` the file.

See `MERGE-STRATEGY.md` for the per-file class matrix that explains
which strategy was used for each file and why.

---

## Step 3 — Verify

After all sidecars resolved:

```sh
git status
# Should show modified files but no untracked .v10-customized sidecars

bash scripts/pack-help.sh
# Should print the merged HELP-FRAGMENT (pack-side header + tracker section
# inlined + colloquial mappings). If pack-help.sh is missing, the v11
# install didn't land — re-run the migrator.

# Confirm trinity addenda landed:
grep "Quick reference" CLAUDE.md AGENTS.md GEMINI.md
# Should show the "## Quick reference" block in all three files.

# If you have a Claude Code / Codex / Antigravity install:
ls .claude/skills/pack-help/SKILL.md \
   .codex/skills/pack-help/SKILL.md \
   .agents/skills/pack-help/SKILL.md
# All three should exist.
```

Open a PM Chat session in your client project: `/pm-startup` should
now report v11 as the active pack version and read in the new
`## Quick reference` blocks.

---

## Step 4 — Commit

```sh
git add -A
git diff --staged | less
# Sanity-check the diff. Highlights:
#   - CLAUDE.md / AGENTS.md / GEMINI.md gained a "## Quick reference"
#     block (or a fresh template if you had no customizations).
#   - .gitignore may have been merged with new pack additions.
#   - docs/pack/HELP-FRAGMENT.md is new.
#   - tracker.toml.example is NOT installed (tracker deferred).
#   - .github/ISSUE_TEMPLATE/{work-item,inbound,config}.yml are new.
#   - per-CLI pack-help skill / command are new.
#   - Any reconciliation files you edited.

git commit -m "chore: migrate to AI Agent Config Pack v11"
```

---

## Step 5 — Phase B (tracker opt-in) — DEFERRED

Tracker integration is DEFERRED indefinitely (no release version).
Flat-file per-entry is the sole supported mode; the ability to
flip to tracker mode is blocked and `pack tracker init` refuses with a
deferred message. There is no opt-in flow to run — migration is
Phase-A complete without it.

The tracker code (the TrackerProvider abstraction, the forward/reverse
migrators, and the `pack tracker` verbs) is retained DORMANT and
test-covered for a possible future resumption. Continue to use the
flat-file per-entry trees under `docs/project/` (visible in `git log`,
no GitHub round-trip).

---

## Lessons learned — customization preservation

The historical v10 migrator (the v9->v10 script, sunset in v11) had a
defect class that silently destroyed project customizations on a small
set of file shapes. v11 fixes this with the customization-preserve
library:

1. **Truthful report.** Every file the migrator touches appears in
   exactly one section of `report.md`. No silent drops.
2. **Per-class strategies.** 11 classes covering trinity (3-way merge),
   structured configs (JSON/TOML allowlist), per-CLI agents (`x-`
   reserved-prefix preservation), pack-shipped scripts (3-way text),
   and so on. See `MERGE-STRATEGY.md`.
3. **Single-slot sidecars.** `<file>.v10-customized` for the migrator,
   `<file>.pre-update` for `init-project.sh --update`. The migrator
   refuses to run when its backup directory already exists; `--update`
   refuses when prior `.pre-update` sidecars are present. Both gates
   prevent silent overwrites.
4. **CI regression guard.** validate-pack Check 25 runs a
   4-fixture synthetic on every push to fail-closed if the
   customization-preserve library regresses. Class-coverage delegated
   to `scripts/tests/test-customization-preserve.sh` which CI runs
   end-to-end.

If the migrator reports `customization-detected-needs-reconciliation`
on a file you didn't customize, that's a defect — please file an
inbound issue (`pack-feedback-friction` or `pack-feedback-prompt`)
against the pack with the
`.pack-migrate-v10-to-v11/dispositions.tsv` row attached.

---

## Step 6 — Merge to the default branch

Once you've committed and pushed your migration branch:

1. Open a PR titled e.g. `chore: AI Agent Config Pack v11 migration`.
2. Verify CI green (validate-pack + tests).
3. Merge.

The pack itself does not enforce branch protection — that's per-project
policy. We recommend requiring CI green before merge.

---

## Rollback

The migrator writes a faithful working-tree backup at
`.pack-migrate-v10-to-v11-backup/` before any changes. To revert:

```sh
cd <target>
rm -rf .pack-migrate-v10-to-v11
rsync -a --delete \
    --exclude=.git/ \
    --exclude=.pack-migrate-v10-to-v11-backup/ \
    .pack-migrate-v10-to-v11-backup/ ./
git diff   # inspect; should be empty if backup is faithful
rm -rf .pack-migrate-v10-to-v11-backup
```

The migrator's `S6` final message prints this exact recipe. The legacy
`scripts/restore-from-backup.sh` is for v9.3→v10 backups and should
NOT be used for v11 restore.

If you'd already committed: `git revert HEAD` is the safest single-step
revert (preserves the backup directory in case you want to forensically
inspect what the migrator did).

---

## Project-type-specific notes

### Apple / Swift

- Conditional Swift scripts (`scripts/format-swift.sh`,
  `scripts/test-swift.sh`, `scripts/validate-swift.sh`) are
  preserved; their content may have shifted between v10 and v11 — let
  the migrator's 3-way merge handle it.
- `XCODE_SCHEME` and `XCODE_DESTINATION` keys in `.claude/settings.json`
  are preserved unchanged (`claude-settings` allowlist).

### Python

- `pyproject.toml`, `pyrightconfig.json` are project-only files; the
  migrator does not touch them.
- `scripts/test-python.sh`, `scripts/validate-python.sh` get the same
  3-way text dispatch as Swift's parallel scripts.

### Mixed / gRPC

- `scripts/proto-gen.sh`, `scripts/validate-proto.sh` are preserved
  via `pack-script` 3-way text.
- `proto/` is project-only and untouched.

---

## Troubleshooting

### "v10 baseline tag 'v10' not present in pack repo"

The pack repo doesn't have the `v10` git tag locally. Fix:

```sh
git -C "$PACK" fetch --tags
git -C "$PACK" tag --list v10
```

If still missing, the pack repo was checked out without tags; re-clone
or `git fetch origin v10:v10`.

### Migrator finishes but I can't run `pack help`

`scripts/pack-help.sh` is a pack-repo verb (it lives at the pack repo
root, not in your project). You run it from the pack repo or via your
CLI's `/pack-help` command. The CLI commands ARE installed into your
project (`.claude/skills/pack-help/SKILL.md`, etc.) and route to your
**pack repo's** `scripts/pack-help.sh`.

### "refusing to proceed: prior --update sidecars present"

You ran `init-project.sh --update` previously and didn't reconcile the
sidecars. Resolve them (edit destination, remove `.pre-update`) before
re-running. If you don't intend to keep any of the sidecar content,
just `find . -name '*.pre-update' -delete` — but only do this if you're
certain.

### One reconciliation file is corrupt / unreadable

The structured diff at `.pack-migrate-v10-to-v11/diffs/<flat>.three-way.diff`
shows BASE→OURS and BASE→THEIRS separately. If the live destination got
corrupted (e.g., encoding mismatch), `cp <sidecar> <destination>` to
restore your pre-migration copy, then manually apply the v11 changes
the diff shows.

### My customizations weren't preserved

This should never happen for the 12 documented classes (`MERGE-STRATEGY.md`).
If it does:

1. Save `dispositions.tsv` and the relevant `<file>.v10-customized`.
2. File an inbound issue with the disposition row + the file's pre-migration content.
3. Restore from backup (Rollback section above).
4. Wait for the pack-side fix to land before re-attempting.

Validate-pack Check 25 + `test-customization-preserve.sh` are the CI
guards against this; if either is silenced or removed, customization-
loss defects can re-emerge.

---

## What to do after migration

1. **Read the `## Quick reference` block** at the top of each trinity
   file. The pack-startup / pm-startup recommendation is the documented
   first action for new sessions.
2. **Phase B is deferred.** Tracker integration is deferred
   indefinitely; flat-file per-entry is the sole supported mode and there is
   no opt-in to decide on. Continue with flat-file `BACKLOG.md` /
   per-entry tracking — startup surfaces no tracker recommendation.
3. **Commit early after each reconciliation.** Don't accumulate a
   100-line reconciliation diff. Commit each `<file>.v10-customized`
   resolution as a separate small commit.
4. **Re-run validate-pack** locally before pushing if you're a pack
   maintainer. CI will catch you, but local-first is faster.

---

## Automated migration via AI CLI

If you'd rather have your AI CLI run the migration:

```
prompt
You are the migration agent for [PROJECT_NAME at <abs path>].

The AI Agent Config Pack v11.0 is available at $PACK. Please:

1. Run `bash scripts/migrate-v10-to-v11.sh` (this directory).
2. Read `.pack-migrate-v10-to-v11/report.md`.
3. For every "Files needing manual reconciliation" row, open the
   sidecar and the destination, and propose a unified diff that
   merges my pre-migration content into the new pack template.
   Show me each proposed diff before applying.
4. After all reconciliations, run `git status` and confirm there
   are no `.v10-customized` files remaining.
5. Print the v11 trinity "## Quick reference" block from CLAUDE.md
   to confirm the addenda landed.
```

The migrator itself is non-interactive (no prompts); the AI CLI
handles the reconciliation step.
