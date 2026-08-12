# Setup Guide — Existing Project

This guide walks you through adding the AI Agent Config Pack v11.0 to
an **existing project** that has source code and/or documentation but
no prior AI agent configuration.

**Use this guide when:**
- The project has existing source, docs, or both.
- There is **no existing** `.claude/`, `.codex/`, `.agents/` directory
  or `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` file at the project root.
  (If any AI config is present, `init-project.sh` stops with exit
  code 20 and routes you to `MIGRATION-v10-to-v11.md` or asks you to
  archive the other AI tooling first.)

**If your project is fresh (no code yet):** see `SETUP-NEW.md`.

**If your project is already on a prior pack version (v10):** see
`MIGRATION-v10-to-v11.md`. (Older `MIGRATION-v9-to-v10.md` is
historical, available via `git checkout v10 -- <path>`.)

---

## Prerequisites

- **Clean working tree.** `git status --porcelain` must return empty.
  Commit or stash any pending changes before starting — the pack
  install should land as an isolated diff you can review cleanly.
- **`pack-init` side branch.** All pack-install changes land here,
  not on `main`, so you can review and either merge or abandon them
  without polluting main.
- **Pack cloned locally.** Clone the `optiquity-ai-agent-config-pack`
  repo to a stable location and use that location wherever
  `/path/to/pack` appears in this guide. Export `$PACK`:

  ```bash
  export PACK=/path/to/pack
  git -C "$PACK" checkout v10.0   # or v10 floating tag
  ```

---

## Step 1 — Create the `pack-init` branch

```bash
cd /path/to/your-project
git checkout main
git pull
git checkout -b pack-init
```

All subsequent commands in this guide assume you're on `pack-init`.

---

## Step 2 — Run `init-project.sh` and review the preview

```bash
"$PACK/scripts/init-project.sh" .
```

For CI / scripted installs, pass `--yes` to bypass the `Proceed?` confirm
and install without prompting. A non-TTY run without `--yes` declines
(exit 0) with a message naming `--yes`; `--no-interactive` forces that
non-prompting path explicitly. Both apply to fresh install only.

The script runs detection in **read-only** mode first. Nothing is
written until you confirm. Study each section of the preview
carefully before typing `y`:

- **Classification.** Expect `existing-source` or `existing-bare`
  (the "existing" paths). If you see `already-configured`, the script
  stops (exit 20) — you have prior AI config that the script won't
  overwrite.
- **Language markers found.** Confirm the detected languages match
  your project. If markers are missed (e.g., your Python project
  lives in a subdirectory deeper than depth 2), you may need to
  reorganize or manually remove the conditional files post-install.
- **Pack skill coverage.** For each detected language, the preview
  reports `FULL` or `NO COVERAGE`. A `NO COVERAGE` flag means the
  pack does not ship skills for that language (e.g., Kotlin,
  TypeScript in v11.0). Installation still works — skill gaps are
  handled in Step 11 below.
- **Planned operations — ADD.** Lists every new directory and file
  the script will create (`.claude/agents/`, `.codex/agents/`, the
  Antigravity agent bundle `.agents-plugin/optiquity-agents/`, skills
  (`.claude/skills/`, `.codex/skills/`, `.agents/skills/`), `docs/pack/`,
  `scripts/` entries, context files).
- **Planned operations — MERGE.** `.gitignore` entries that will
  append under a `# --- AI Agent Config Pack additions (v11.0) ---`
  header. Existing patterns are preserved.
- **Planned operations — CONDITIONAL REMOVE.** Pack-shipped files
  that don't apply to your detected languages and will not be kept.
  Example: Python-only project → `scripts/bootstrap-swift.sh`,
  `scripts/format-swift.sh` removed.
- **Planned operations — SKIP.** Existing project files the script
  will **not** overwrite: `README.md`, `LICENSE*`, language manifests,
  any `docs/` file that already exists, any `scripts/` file that
  already exists.

If you see something unexpected, answer `N` (or just Enter) to
decline. The script exits 0 with no changes. Investigate first, then
re-run.

When the preview matches your expectations, answer `y` to proceed.

---

## Step 3 — Review the stage verification output

The script runs eleven stages (S0..S10) and prints per-stage output.
Each stage runs inline verification before the next begins. A
failure at any stage prints a diagnostic and exits non-zero:

| Code | Meaning |
|---|---|
| 0 | Success |
| 10 | `$PACK` invalid |
| 11 | Not a git repo |
| 12 | Working tree not clean |
| 20 | STOP — existing AI config |
| 21–30 | Stage N failure (code = 20 + N) |
| 31 | Blast-radius sweep failure |
| 40 | Conditional-removal failure |
| 99 | Internal error |

If the script exits non-zero after S1, inspect `git status` and
`git diff`. Reset with `git reset --hard && git clean -fd` if you
need to start over. Re-running is safe — the script is deterministic
and reruns idempotently on a clean tree.

On success, the script prints an **end-of-run PM chat kickoff prompt**
at the end. Copy or note this prompt — Step 8 uses it.

---

## Customizing the trinity files

`CLAUDE.md`, `AGENTS.md`, and `GEMINI.md` are **pack-owned** — the pack
rewrites their canonical body on every update. To make your own edits
survive an update byte-for-byte, wrap them in a **project-owned marker
pair**. Content INSIDE a pair is yours and is preserved; content OUTSIDE
is pack-owned and may be overwritten. There are two shapes:

- **Shape A — body wrap.** Keep the pack's `##` heading and wrap only the
  body lines you own between `<!-- BEGIN project-owned -->` and
  `<!-- END project-owned -->`. Use this to add project text under a
  section the pack also owns.
- **Shape B — whole-section wrap.** Wrap an entire `##` section, heading
  included, in the marker pair. Use this for a section you keep and
  customize (including a former optional section — see Step 4) or a
  brand-new project-only section.

**Adopting a project that already has overlapping content.** An existing
project often already carries content that overlaps a pack-owned trinity
section. To keep your version, wrap it as **Shape B using the same `##`
heading** as the pack section — a same-name Shape B pair overrides the pack
body wholesale on every update. If your heading differs from the pack's,
name the pack's original heading in a `renamed-from` annotation on the BEGIN
marker (e.g. `<!-- BEGIN project-owned: renamed-from "## Anti-patterns — never introduce these" -->`)
so the pack treats your section as a replacement, not a new one.

The trinity ships an empty seed pair under `## Project addenda` to start
from. For the full procedure — placeholders, the same-name override, and
the `renamed-from` annotation — see `docs/pack/PM-CHAT.md` for how to add
project-owned content to trinity files.

---

## Step 4 — Fill in context file placeholders

The pack ships `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` with `[PLACEHOLDER]`
placeholders and optional sections (each marked by an `<!-- OPTIONAL: … -->`
hint above its heading). Fill in a minimum set now; the PM chat will finish
the rest during kickoff (Step 10):

1. Fill `[PROJECT_NAME]`, `[PLATFORM_TARGETS]`, `[TRANSPORT]` in all
   three files.
2. Fill `[PLATFORM_DEFAULTS]` for your project type.
3. Delete the optional (`<!-- OPTIONAL: … -->`-hinted) sections that don't
   apply; if you keep and customize one, wrap it as Shape B (see
   **Customizing the trinity files** above).
4. Leave `[PLATFORM_ARCHITECTURE]`, `[LANGUAGE_RULES]`, `[GRPC_RULES]`,
   `[PLATFORM_SECURITY]`, `[PLATFORM_TESTING]`,
   `[PLATFORM_ANTIPATTERNS]` for the PM chat.
5. Leave the `**Active skills:**` line as a placeholder; the PM chat
   fills it.

---

## Step 5 — (PM chat handles this during kickoff)

*Step number 6 is intentionally absent — Steps 5–6 collapsed into this
Step 5. Step numbering is preserved for cross-doc reference stability;
Steps 7–12 below retain their original numbers.*

On shell-capable surfaces, the PM chat runs kickoff auto-discovery
(INSTALL-PROCEDURES.md Procedure 7) after you paste the kickoff prompt in
Step 8. It fills in Apple Xcode scheme variables and installs Xcode
companion files — each behind an approval gate. **You do not need to
run anything in this step on a shell-capable surface.**

On surfaces without shell access (Claude Web, ChatGPT Web), declare
`manual` when the PM chat asks and follow `SETUP-NEW.md § Manual
fallback` (sub-sections 5.A and 5.D — Xcode scheme variables and
Xcode companion files; 5.B and 5.C apply only to new projects).

---

## Step 7 — Commit the pack-init changes

```bash
git add -A && git status           # review — expect new files only, no modifications to existing source
git diff --stat
git commit -m "Add AI agent configuration (v11.0 pack install)"
```

Do **not** merge `pack-init` into `main` yet. Step 10 may add more
files (architecture assessment output). Merge after the PM chat
kickoff if you're satisfied.

---

## Step 8 — Start the PM chat and paste the kickoff prompt

> **Prerequisite — design brief.** If your existing project has
> `docs/ARCHITECTURE.md` or similar, that IS your design brief — PM
> chat will read it in Step 9. If your project has no architecture
> documentation, produce a design brief in a separate conversation
> first (the PM chat consumes briefs, it does not author them).

Pick one PM chat surface (Desktop, Claude Code CLI, Codex CLI, or
Antigravity CLI) per `SETUP-NEW.md` Step 10 setup instructions. When the
session is ready, paste the kickoff prompt that `init-project.sh`
generated at the end of Step 3.

The prompt includes:

- Your project's absolute path.
- Pack version banner.
- **An existing-docs pointer** (for existing-project installs —
  names the specific files already present at `docs/ARCHITECTURE.md`
  and `README.md`).
- **A skill-gap instruction** (if the preview flagged any — names
  the uncovered languages/platforms and asks the PM chat to append a
  PACK-FEEDBACK.md entry during kickoff).

---

## Step 9 — PM chat onboarding — existing docs pointer

This is the key procedure that distinguishes existing-project setup
from new-project setup. The PM chat's kickoff reads the existing
documents before generating any architecture content of its own:

1. PM chat reads `docs/ARCHITECTURE.md` (if present) and `README.md`
   to learn what you have already documented.
2. PM chat asks you to confirm which other existing documents it
   should read. Typical candidates:
   - Inline design notes (e.g., `docs/design/*.md`).
   - ADRs (`docs/adr/*.md` or similar).
   - Wiki exports.
   - Historical `CHANGELOG.md` entries.
   - Any project-specific style or convention doc.
3. You point the PM chat at the relevant additional files.
4. PM chat reads them, then proceeds with the kickoff workflow using
   your existing documentation as the authoritative context — not
   by generating a clean-slate architecture.

This is crucial: the PM chat must **not** overwrite your existing
architecture decisions. Its job in an existing-project install is
to **reconcile** its understanding with what you have documented,
and flag gaps where the pack's conventions differ from your current
approach.

---

## Step 10 — PM chat kickoff and architecture assessment

After reading existing docs (Step 9), the PM chat runs the rest of
the kickoff workflow:

1. Fills the remaining `[PLACEHOLDER]` sections in `CLAUDE.md`,
   `AGENTS.md`, `GEMINI.md` based on your existing architecture.
2. Writes the **Active skills:** line in each trinity file, using
   the skill set derived from `docs/pack/PLATFORM-SKILLS.md`.
3. Produces a reconciliation report listing:
   - Architecture decisions you have already documented (preserved).
   - Where your existing architecture aligns with pack conventions.
   - Where your existing architecture diverges (noted for your
     review — no automatic changes).
   - Any optional sections (each `<!-- OPTIONAL: … -->`-hinted) in the
     context files that your project does not use (candidates for removal).
4. Surfaces these decisions for your approval before committing.

Commit the trinity-file placeholder fills and any small doc updates
the PM chat produces:

```bash
git add -A && git diff --stat
git commit -m "Fill in context file placeholders (v11.0 pack install)"
```

---

## Step 11 — Skill gap follow-up (if applicable)

If the `init-project.sh` preview flagged a skill-coverage gap (e.g.,
your project uses Kotlin or TypeScript — not covered by v11.0 pack
skills), the PM chat appends an entry to
`docs/pack/PACK-FEEDBACK.md` during kickoff with:

- The language or platform name.
- The project stage (from the kickoff output).
- A short note on the kinds of guidance the project would benefit
  from.

This log is delivered back to the Pack Chat at a workflow boundary
(per `METHODOLOGY.md` Part 10). You don't need to do anything extra;
just confirm the entry is present:

```bash
grep -A 5 "Language/platform coverage gaps" docs/pack/PACK-FEEDBACK.md
```

In the meantime, agents will load whatever pack skills DO apply to
your project. Uncovered languages have no agent-side guidance beyond
the generic rules in the context files.

---

## Step 12 — Continue as normal

Once Steps 1–11 are complete, merge `pack-init` into `main`:

```bash
git checkout main
git merge --no-ff pack-init -m "Merge pack-init: add AI agent configuration (v11.0)"
git branch -d pack-init
```

From this point on, follow the standard workflows in
`supporting-docs/METHODOLOGY.md` (Part 5 — Standard Workflows).
Your per-phase cycle is now:

1. PM chat generates the coder prompt (`docs/pack/prompts/coder.md`
   Variant: standard) for the current phase.
2. Run the coder via `./agent-run.sh codex --agent coder`.
3. PM chat generates the reviewer prompt
   (`docs/pack/prompts/reviewer.md` Variant: standard).
4. Run the reviewer via `./agent-run.sh claude --agent reviewer`.
5. Triage reviewer findings; apply fix-cycle prompt
   (`docs/pack/prompts/coder.md` Variant: fix-cycle) if needed.

---

## Reference

### What NOT to put in Git

`.gitignore` handles these automatically:

- `.claude/settings.local.json` — machine-specific Claude Code
  permission overrides.
- `.mcp.json` — local MCP server configuration.
- `generated/swift/` and `server/src/generated/` — generated code.
- `.buf/` — buf CLI cache.
- `.pack-migration-backup/` — migration-script backup (only present
  after a later upgrade).

Commit everything else: `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`,
`agent-run.sh`, `.claude/`, `.codex/`, `.agents/`, `.agents-plugin/`,
`scripts/`, `docs/pack/`.

---

## Migrating a Gemini-configured project to Antigravity

If your existing project was previously configured with the pack's
**Gemini CLI** support (a v10-pack project with a `.gemini/` tree at
the project root), this is a **migration**, not a fresh install — run
`MIGRATION-v10-to-v11.md` instead of this guide. v11 replaces the
Gemini CLI leg with **Antigravity CLI** (`agy`), and the v10 → v11
migrator handles the transition automatically. What the migrator does
with your Gemini config:

- **Pack agents become the Antigravity bundle.** The 16 pack agents
  install as an Antigravity plugin bundle at
  `.agents-plugin/optiquity-agents/` (agents installed
  replace-if-different — a pack agent that changed between versions is
  refreshed; one you customized in place is preserved or sidecared).
- **Your custom (`x-`) agents are auto-lifted into the bundle.** Any
  custom agent under your old `.gemini/agents/x-*.md` is copied into
  `.agents-plugin/optiquity-agents/agents/` and becomes a live
  Antigravity agent. There is nothing to re-create by hand.
- **The departing `.gemini/` tree is retired as a backup.** Your whole
  `.gemini/` directory is moved (never deleted) into a root-level
  `gemini-retired-docs/` holding directory as a recovery copy. The
  originals also remain in your project's git history. If
  `gemini-retired-docs/` trips your CI, add it to your `.gitignore`.
- **Skills land at `.agents/skills/`.** Antigravity reads loose skills
  from `.agents/skills/<name>/SKILL.md`; the pack distributes them there
  alongside the `.claude/` and `.codex/` copies.

After migration, install the Antigravity agent bundle once so the
roster is available to every session:

```bash
agy plugin install ./.agents-plugin/optiquity-agents
```

<!-- RE-VERIFY at impl: agy plugin install runtime re-read semantics (does Antigravity re-read the bundle after the migrator updates agents/*.md in place, or require a re-install?), antigravity.google/docs -->

See `MIGRATION-v10-to-v11.md` for the full migration narrative,
including the post-migration surface list and reconciliation workflow.

---

## Upgrading later

When a new pack version ships, upgrade your project by running the
migration script for your current → target version. Migration guides
follow the naming convention `MIGRATION-vN-to-vM.md` and always live
in `supporting-docs/` of the target pack version.
