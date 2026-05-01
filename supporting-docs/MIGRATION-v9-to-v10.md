# Migration Guide — v9.3 to v10.0

This guide covers upgrading existing projects from AI Agent Config Pack
v9.3 to v10.0. It is self-contained — follow these steps in order
without needing any other document.

> **Automated option:** If you prefer to have an AI CLI session
> (Claude Code, Codex, or Gemini) execute the migration for you with
> your review and approval at each step, see the **"Automated migration
> via AI CLI"** section at the end of this guide. You can skip the
> manual steps below entirely.

For v8 → v9 upgrades: use the v9 pack (`git -C "$PACK" checkout v9.3`)
which contains `MIGRATION-v8-to-v9.md`. Apply v8 → v9 first, then this
guide.

> **v9.x → v10.0 baseline requirement:** the migration script
> (`migrate-v9-to-v10.sh`) requires the project to be at v9.3
> specifically. v9.0 / v9.1 / v9.2 projects must apply the relevant
> v9 increments first (see `MIGRATION-v8-to-v9.md` in the v9 pack and
> any post-v9.0 patch notes) before running this guide.

---

## What changed in v10

Four BD items shipped in v10.0:

- **BD-044 — Project initialization tooling.** New `scripts/init-project.sh`
  detects project state (five classes), previews every operation, and
  asks for explicit confirmation before writing. A three-path
  QUICKSTART.md router (NEW / EXISTING / MIGRATE) points at this guide
  for v9.3 projects.
- **BD-045 — Capabilities pattern.** New architecture best practice
  recommended alongside LSP (LSP remains required; capabilities is
  recommended). Added to the trinity files (`CLAUDE.md`, `AGENTS.md`,
  `GEMINI.md`), the per-language skills (`apple-architecture-core`,
  `python-best-practices`), the `architecture-review` skill, and the
  `auditor-architecture` agent. Back-reference added to
  `audit-methodology` rule 15.
- **BD-046 — Prompt reorganization + custom-agent support + migration
  tooling.** Three separable shifts bundled here:
  - The v9.3 monolithic `PROMPT-TEMPLATES.md` is decomposed into one
    file per agent under `docs/pack/prompts/`, one `## Variant: <slug>`
    H2 per template. Templates 1–14 become variant slugs mapped into
    the relevant per-agent file.
  - Project-specific agents and skills are formalized via the reserved
    `x-` filename prefix. INSTALL-PROCEDURES.md Procedure 5 documents the
    creation, registration, detection, and adoption workflows.
  - New migration tooling: `scripts/migrate-v9-to-v10.sh` with shared
    detection library `scripts/lib/detect.sh` and two Python splice
    helpers `scripts/merge-platform-skills.py` and
    `scripts/merge-trinity.py`. Procedure 5-C.1 reconciles customized
    `PROMPT-TEMPLATES.md` content after migration.
- **BD-047 — PM chat kickoff auto-discovery and install-check.** New
  `INSTALL-PROCEDURES.md` Procedure 7 paired with the `docs/pack/prompts/pm-chat.md`
  `Variant: kickoff` continuation pointer. On shell-capable surfaces
  (Claude Code CLI, Codex CLI, Gemini CLI, Claude Desktop with Desktop
  Commander), the PM chat runs read-only discovery (`xcodebuild -list`,
  `xcrun simctl list devices available`, brew detection) and offers
  approval-gated Forms (R / I / E / M) for every install and edit. On
  non-shell surfaces (Claude Web, ChatGPT Web), the PM chat points at
  `SETUP-NEW.md § Manual fallback` (sub-sections 5.A–5.D) and waits
  for developer-reported values. SETUP-NEW.md Steps 5–8 collapse into
  a single Step 5 that routes to either path; SETUP-EXISTING.md Step
  5 follows the same pattern.

Three structural shifts follow from those BD items:

1. **Prompt directory** `docs/pack/prompts/` replaces
   `supporting-docs/PROMPT-TEMPLATES.md`. Per-agent direct read by the
   PM chat; no more RAG ingestion of prompt content.
2. **`x-` prefix convention.** The pack reserves filenames beginning
   with `x-` for project-owned customization. `validate-pack.py` Check
   8 enforces zero `x-` files in the pack repo itself; any `x-*` file
   in a project directory is project-owned.
3. **Capability-addition mechanism.** Future capability additions
   (language, platform, protocol, role) run through
   `scripts/add-capability.sh` in the pack followed by METHODOLOGY.md
   Procedure 6.

### What does NOT change from v9.3

- **Agent roster.** The same 16 pack agents (architect, auditor +
  seven subagents, coder, docs-researcher, grpc-schema, planner,
  repo-ops, reviewer, tester) remain.
- **Skill roster.** The same 30 pack skills remain.
- **Cross-tool interchangeability.** Claude Code, Codex, and Gemini
  CLI continue to run the same agents and skills. `agent-run.sh`
  orchestration unchanged.
- **PACK-FEEDBACK.md loop.** Observation-only feedback log, delivered
  in batches at workflow boundaries. Unchanged.
- **Desktop / CLI surface options.** Claude Desktop + filesystem MCP,
  Claude Web + GitHub connector, all three CLIs — all continue to
  work.

---

## Before you start

Pre-conditions (the migration script enforces these; listed here so
you know what to expect at the S0 pre-flight):

1. **v9.3 baseline.** `docs/pack/PROMPT-TEMPLATES.md` exists, 16 pack
   agents are in `.claude/agents/`, `.gemini/agents/` exists with
   native subagent files, `docs/pack/PLATFORM-SKILLS.md` is present.
2. **Working tree clean.** `git status --porcelain` is empty. Commit
   or `git stash` before migrating.
3. **Pack v10 available.** Clone or pull the pack repo and check out
   the v10 tag or branch. Set `PACK` to its absolute path.
4. **Migration branch.** The script creates branch `migration-v9-to-v10`
   on first run (or requires you to be on it for resumed runs).

### Recommended setup

```bash
# In your project directory:
cd ~/Developer/your-project
git checkout main
git pull
git status          # expect: clean

# Make sure the pack repo is current and checked out at v10:
PACK=/path/to/optiquity-ai-agent-config-pack
git -C "$PACK" fetch --tags
git -C "$PACK" checkout v10.0   # or v10 floating tag
```

---

## Step 1 — Run the migration script

```bash
cd ~/Developer/your-project
PACK=/path/to/optiquity-ai-agent-config-pack
"$PACK/scripts/migrate-v9-to-v10.sh"
```

The script executes eight stages (S0–S7) in order. Each stage writes
a sentinel file in `.pack-migration-backup/v9.3-to-v10.0/` so a
resumed run skips completed stages.

| Stage | What it does |
|---|---|
| **S0** | Pre-flight: clean tree check, migration-branch creation, pack/v9.3-tag validation, baseline invariants, `x-` audit, improperly-added audit, backup-dir creation. If prior-run sentinels exist, prompts Resume / Start fresh / Abort. |
| **S1** | Selective-replace agent files across the three tool directories (`.claude/`, `.codex/`, `.gemini/`); `x-*` agents untouched. |
| **S2** | Selective-replace pack skill directories across the three tools; `x-*` skill directories untouched. |
| **S3** | Replace `scripts/`, `agent-run.sh`, `.codex/config.toml`, `.claude/settings.json`, `.mcp.json.example` from pack; prior versions backed up. |
| **S4** | Create `docs/pack/prompts/` and copy the 10 per-agent files from pack (PROMPT-AUTHORING.md was removed in v10.0; directory guidance lives in METHODOLOGY.md § Prompt Authoring Principles). |
| **S5** | Splice-merge `PLATFORM-SKILLS.md` (via `merge-platform-skills.py`) and the three trinity files (via `merge-trinity.py`) — project-owned `## Custom agents` / `## Custom skills` sections, `### Custom agents` sub-section, and the `**Active skills:**` line are preserved. Pack-owned docs (PM-CHAT.md and METHODOLOGY.md, both at `docs/pack/`) are copied verbatim from pack. If a stale root-level `METHODOLOGY.md` is present pre-migration (legacy v10-dev shape), it is backed up and removed. |
| **S6** | Diff project's `docs/pack/PROMPT-TEMPLATES.md` against v9.3 baseline. If identical → backup + delete. If diverged → backup + move to `docs/pack/PROMPT-TEMPLATES.md.v9-customized` (Procedure 5-C.1 reconciliation flag set). |
| **S7** | Write post-migration report to `.pack-migration-backup/v9.3-to-v10.0/report.md`. |

The script does NOT commit. Review `git diff` and the report before
committing.

If the script stops with an error at any stage:

- Read the diagnostic.
- Do **not** attempt manual recovery by editing individual files.
- If the issue is obvious (e.g., missing `$PACK`), fix it and re-run;
  the sentinel-based resume will skip completed stages.
- If the issue is unclear, see §14 Troubleshooting below or consider
  Rollback (§12).

---

## Step 2 — Review the migration report

```bash
cat .pack-migration-backup/v9.3-to-v10.0/report.md
```

Sections to read carefully:

- **Customization status.** Either `customization: none` (v9.3
  PROMPT-TEMPLATES.md was unmodified — nothing to reconcile) or
  `customization: divergence detected; reconciliation flag set`
  (project-specific additions live in `PROMPT-TEMPLATES.md.v9-customized` and need PM
  chat reconciliation via Procedure 5-C.1 at first startup).
- **x-files preserved.** A list of project-owned `x-*` agents, skills,
  and prompt files that the migration script left untouched. Expect
  these to be `(none)` on most v9.3 projects unless you introduced
  custom agents.
- **Improperly-added files.** Any non-pack, non-`x-` file inside the
  seven scan locations. These survive migration but are invisible to
  the PM chat's agent routing and skill-load lists. Register them via
  Procedure 5.3 (Unregistered) or adopt them via Procedure 5.4
  (Improperly added) after migration.

---

## Step 3 — Verify

Run the standard verification scripts from the project root:

```bash
./scripts/bootstrap.sh      # installs any missing dev dependencies
./scripts/validate.sh       # pack-level validation per project type
```

Additional sanity checks:

```bash
# Agent-count invariants (expect 16 pack agents per tool, plus any x-* you have)
ls .claude/agents/*.md  | wc -l
ls .codex/agents/*.toml | wc -l
ls .gemini/agents/*.md  | wc -l

# Skill-count invariants (expect 30 pack skills per tool, plus any x-*)
ls -d .claude/skills/*/  | wc -l
ls -d .codex/skills/*/   | wc -l
ls -d .gemini/skills/*/  | wc -l

# Prompts directory populated (expect 10 per-agent files)
ls docs/pack/prompts/ | wc -l

# No stray x-* in pack locations — the pack itself ships zero `x-` files
# (Check 8 of validate-pack.py). Your project may have `x-*` files; those
# are custom per Procedure 5.
```

---

## Step 4 — First PM chat run

Start a fresh PM chat session (see PM-CHAT.md for the per-tool startup
commands). The PM chat's startup flow runs the detection scan
(INSTALL-PROCEDURES.md Procedure 5.5) automatically.

Expected behaviors depending on what the migration report flagged:

- **Procedure 5-S — Post-migration housekeeping (always runs).** The PM
  chat detects the `postrun-pending` sentinel written by `migrate-v9-to-v10.sh`
  S7 and invokes Procedure 5-S (INSTALL-PROCEDURES.md). The procedure
  scans STATUS.md for stale `**AI Agent Config Pack**: v9` markers and
  the trinity files (CLAUDE.md / AGENTS.md / GEMINI.md) for unfilled
  placeholders (`[PROJECT_NAME]`, `[PLATFORM_TARGETS]`, `[TRANSPORT]`,
  `[PLATFORM_*]`, and the Active-skills line). Findings are surfaced;
  the developer approves / edits / skips each item. The procedure
  self-cleans on completion (deletes the sentinel). If either task
  reports "nothing to do," the procedure exits cleanly.
- **No flags raised (beyond Procedure 5-S).** PM chat reports the
  project is cleanly migrated; proceed with Workflow 2 / next phase as
  normal.
- **`PROMPT-TEMPLATES.md.v9-customized` present in `docs/pack/prompts/`.** PM chat invokes
  Procedure 5-C.1 (INSTALL-PROCEDURES.md): reads `PROMPT-TEMPLATES.md.v9-customized`,
  surfaces each customization with a proposed v10 placement (variant
  slug), and asks you to approve / modify / reject each item. After
  reconciliation, PM chat offers to remove `PROMPT-TEMPLATES.md.v9-customized`.
- **Improperly-added files flagged.** PM chat routes to Procedure 5.4
  (adopt / remove / defer) for each flagged file.
- **Unregistered custom files flagged.** PM chat routes to
  Procedure 5.3 (complete registration).

Do not ask the PM chat to reconcile PROMPT-TEMPLATES.md content
manually — Procedure 5-C.1 is designed to walk through it
interactively, and that flow is more reliable than freeform editing.

---

## Step 5 — Custom file registration

For each file the migration report flagged:

- **Unregistered custom** (e.g., an `x-deployer.md` agent file exists
  but is not in PLATFORM-SKILLS.md `## Custom agents` and trinity
  `### Custom agents`): PM chat runs Procedure 5.3 to draft the
  missing registration artifacts. You approve, PM chat commits.
- **Improperly added** (e.g., `.claude/agents/my-helper.md` — not in
  pack roster, not `x-` prefixed): PM chat runs Procedure 5.4.
  Choices: adopt as custom (rename to `x-my-helper`, route to 5.3),
  remove (`git rm` with explicit approval), or defer (stay flagged
  at every subsequent scan).

Registration artifacts per custom agent (Procedure 5.6 reference
tables in METHODOLOGY.md):

| Artifact | Location |
|---|---|
| Claude agent file | `.claude/agents/x-<name>.md` |
| Codex agent file | `.codex/agents/x-<name>.toml` |
| Gemini agent file | `.gemini/agents/x-<name>.md` |
| Per-agent prompt file | `docs/pack/prompts/x-<name>.md` |
| PLATFORM-SKILLS.md `## Custom agents` row | `docs/pack/PLATFORM-SKILLS.md` |
| Trinity routing-table row | `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` (byte-identical) |

---

## Step 6 — Xcode companion files (Apple projects)

If the project is an Apple project and uses the machine-level Xcode AI
config from `xcode-companion-templates/`, refresh those files per
machine. See the README in `xcode-companion-templates/` for the
per-version recipe. v10 does not change the Xcode companion file
format; you only need this step if you want the latest
version-specific content.

---

## Step 7 — Commit

```bash
git status                                # review all changes
git diff --stat                           # summary of modified files
git add -A
git commit -m "chore: migrate to AI Agent Config Pack v10.0

- Applied migration via scripts/migrate-v9-to-v10.sh
- Prompt files reorganized to docs/pack/prompts/ (BD-046)
- Capabilities-pattern additions in trinity + skills (BD-045)
- Custom-agent mechanism placeholders in PLATFORM-SKILLS.md (BD-046)
- Migration report: .pack-migration-backup/v9.3-to-v10.0/report.md"
```

Do NOT push until your team has reviewed the diff (especially the
trinity splices and the `docs/pack/` changes). You can delete the
`.pack-migration-backup/` directory once you're confident the
migration is stable; the pack-owned files can always be refreshed
from the pack repo.

---

## What to do after migration

The migration is a **single atomic session**: the script's
mechanical pass and Procedure 5-C reconciliation both happen on
the working tree of the `migration-v9-to-v10` branch *before any
commit*. The session ends with one commit (success) or a clean
rollback (no commit). Sidecars are never committed — they are
working-tree artifacts that exist only between the script's run
and the final commit-or-rollback decision.

The script produces three classes of result:

1. **Pack updates** — files brought current with v10 with no
   project conflict. Already in the working tree.
2. **Merges** — structured configs (`.claude/settings.json`,
   `.codex/config.toml`) where pack additions and project
   customizations were combined automatically.
3. **Reconciliations** — files where the pack content and your
   project customization diverge in ways that cannot be merged
   automatically. For each such file, the script wrote a
   `.v9-customized` sidecar next to the file holding your
   pre-migration content. The live file holds the new pack content.

### Workflow

1. **Review the migration report** at
   `.pack-migration-backup/v9.3-to-v10.0/report.md`. Run `git diff`
   (which shows tracked-file changes) and `git status` (which
   shows new untracked files including sidecars) to confirm the
   working tree matches the report.
2. **Walk Procedure 5-C in this same session.** For each
   `.v9-customized` sidecar, the chat presents the three-way diff
   and the project's pre-migration content, then asks you to
   decide: keep the new pack content as-is, restore the project
   version, hand-merge the two, or land it under
   `## Project addenda` / `x-*.md`. Procedure 5-C also reconciles
   the trinity preamble (removes `<!-- HOW TO USE THIS TEMPLATE -->`
   blocks, restores the H1 title and project intro from the sidecar,
   replaces `[PROJECT_NAME]` / `[PLATFORM_TARGETS]` / `[TRANSPORT]`
   placeholders) and the PM-CHAT.md preamble. Each sidecar is
   deleted as it is reconciled. Procedure 5-C is in
   `docs/pack/INSTALL-PROCEDURES.md`.
3. **Re-run `bootstrap.sh` and `validate.sh`** after reconciliation
   completes. Reconciliation must not introduce build or test
   regressions. If validation fails, fix in the working tree
   before proceeding.
4. **Inventory check.** Confirm the working tree has no remaining
   sidecars and no placeholders:

   ```bash
   find . -name '*.v9-customized' \
       -not -path './.pack-migration-backup/*' \
       -not -path './.git/*'
   # Expected: empty output

   grep -nE '\[(PROJECT_NAME|PLATFORM_TARGETS|TRANSPORT)\]' \
       CLAUDE.md AGENTS.md GEMINI.md docs/pack/PM-CHAT.md
   # Expected: empty output
   ```
5. **Single migration commit on `migration-v9-to-v10`.**
   `git add -A` (captures both modifications and new untracked
   pack files like `docs/pack/INSTALL-PROCEDURES.md`,
   `docs/pack/prompts/`, `.codex/config.toml.example`,
   `.gemini/settings.json`). Verify `git status` shows no
   `*.v9-customized` files. Commit with a message like
   `feat: v10 — migrate from v9.3 (script + Procedure 5-C reconciliation)`.

   This is the *sole* commit for the migration. Do not commit
   intermediate state.
6. **Merge `migration-v9-to-v10` into your default branch** per
   Steps 5–7 of this document.

### Rollback (if reconciliation reveals an unresolvable defect)

If reconciliation surfaces a problem that cannot be fixed in this
session — typically a defect in the pack scripts or docs — abort
cleanly. The migration leaves no committed trace, and the repo
returns to v9.3 state:

```bash
git checkout -- .
git clean -fd
rm -rf .pack-migration-backup
git checkout main
git branch -D migration-v9-to-v10
```

Report the defect, wait for the pack to be fixed (`git pull` in
the pack repo), then re-run the migration prompt from a clean
v9.3 working tree.

### v10 changes that affect day-to-day workflow

Once the migration commit lands and the branch is merged, brief
your PM chat about the v10 changes that affect day-to-day
workflow:

- **Prompts are per-agent direct read.** When generating prompts, the
  PM chat reads `docs/pack/prompts/<agent>.md` and locates the
  `## Variant: <slug>` H2 for the needed template. No more RAG search
  of a monolith.
- **Detection scan runs at startup and every phase gate.** Procedure
  5.5 requires a scan of the seven detection directories; improperly
  added files will be flagged for adoption/removal.
- **Capability additions run through the script.** If you need to
  add a new pack-supported capability (language, platform, protocol,
  role) later, run `scripts/add-capability.sh` from the pack first,
  then Procedure 6 (coming in v10.0 if not already present).

---

## Rollback

Every destructive operation in the migration script writes a backup
under `.pack-migration-backup/v9.3-to-v10.0/` before the write. Full
rollback is deterministic:

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

Rollback guarantees:

- **No data loss on pack-owned files** (every replaced file backed
  up; manifest records all).
- **No data loss on `x-` files** (never touched, forward or back).
- **No data loss on project-owned docs** (`BACKLOG.md`, `STATUS.md`,
  `ARCHITECTURE.md`, `IMPLEMENTATION_PLAN.md`, `CHANGELOG.md`,
  `PACK-FEEDBACK.md` are not touched by migration).
- **Deterministic recovery** — the rollback commands are a fixed
  sequence.

---

## Project-type-specific notes

### Swift / Apple projects

- If you use `xcode-companion-templates/`, refresh the per-machine
  files per Step 6.
- The v10 capabilities-pattern content lives in
  `apple-architecture-core/SKILL.md` rules 11–14. Your existing
  review cycle picks up the new rules automatically at the next
  architecture review — no manual action required.

### Python projects

- Capabilities-pattern content is in `python-best-practices/SKILL.md`
  rules 14–17. Same note as Apple.
- No Python-specific migration step beyond the generic flow.

### gRPC / monorepo projects

- No gRPC-specific migration step.
- Monorepo language markers (Swift + Python + proto) are all
  preserved by the migration; S9 conditional-removal does not run
  during migration (that is init-project.sh territory for new
  projects).

### Projects with custom agents (pre-existing `x-` files)

- Confirm the migration report shows every `x-` file you expect
  under "x-files preserved."
- After migration, PM chat runs Procedure 5.3 on any custom file
  whose registration is incomplete (e.g., agent file exists but no
  PLATFORM-SKILLS.md row). Approve the drafts, then commit.

---

## Troubleshooting

### The script stops at S0 with "working tree is dirty"

Commit or stash your pending changes before migrating. The migration
is a mutation-heavy operation; a dirty tree would make the diff hard
to review.

### The script stops at S0 with "v9.3 tag not resolvable in $PACK"

The pack repo needs the `v9.3` git tag for the S6 PROMPT-TEMPLATES.md
diff. Fetch tags:

```bash
git -C "$PACK" fetch --tags
git -C "$PACK" rev-parse v9.3        # should print a commit hash
```

### S5 stops with "Active-skills pre-check failed"

The `merge-trinity.py` helper requires each trinity file to have
exactly one `**Active skills:**` line. If any file has zero or
multiple matches, the splice aborts (no trinity files are modified
— per-file atomicity). Inspect the failing file, restore the single
canonical Active-skills line, and re-run. The script's sentinel-based
resume skips S0–S4 on the next run.

### Clean re-run of migration — deleting `.pack-migration-backup/` first

If a prior migration run left sentinels you no longer want (e.g., you
reset the project state manually and want to start the migration from
S0), the S0 pre-flight detects the stale sentinels and prompts:

```
Prior migration run detected — sentinels:
  .pack-migration-backup/v9.3-to-v10.0/stage-S3.done
  ...
Resume [r] / Start fresh [f] / Abort [a]?
```

- **Resume** (`r`) — continue from the first stage without a sentinel.
  Use when the prior run was interrupted cleanly (e.g., `ctrl-c`
  between stages) and the backup directory is intact.
- **Start fresh** (`f`) — `rm -rf .pack-migration-backup/`, then begin
  at S0. Use when you want to discard prior-run state completely.
  You lose the backup dir, so ensure your project's working-tree
  state is what you want to migrate FROM.
- **Abort** (`a` or any other input) — exit 0 without changes.
  Default. Use when you're not sure; investigate first.

If you want to start the migration fresh from outside the script, you
can also delete the backup directory yourself:

```bash
rm -rf .pack-migration-backup
"$PACK/scripts/migrate-v9-to-v10.sh"     # now starts at S0
```

### Migration succeeded but PM chat can't find the prompts

Verify `docs/pack/prompts/` is populated:

```bash
ls docs/pack/prompts/
# expect: 10 agent files
```

If the directory is missing: re-run the script from a clean
state (delete `.pack-migration-backup/` and re-run); S4 should
recreate the directory.

### PROMPT-TEMPLATES.md is still present after migration

The S6 diff step deletes it only if the project's copy is byte-
identical to the v9.3 baseline. If customized, the file is moved to
`docs/pack/PROMPT-TEMPLATES.md.v9-customized` for PM chat reconciliation
(Procedure 5-C.1). If neither happened, check the S6 logs:

```bash
cat .pack-migration-backup/v9.3-to-v10.0/status.txt
```

---

## Automated migration via AI CLI

The following paste-ready prompt works in Claude Code, Codex, and
Gemini CLI (and in Claude Desktop with the filesystem MCP enabled):

```text
You are performing a v9.3 → v10.0 migration of this project using the
AI Agent Config Pack. Set:

PACK="/path/to/pack"

Before starting: verify working tree is clean (git status). If not
clean, stop.

The migration is a SINGLE ATOMIC SESSION. The script's mechanical
pass and Procedure 5-C reconciliation both happen on the working
tree before any commit. The session ends with exactly one commit
(success) or a clean rollback (no commit at all). Do not create
intermediate commits under any circumstance.

Instructions:

1. Read $PACK/supporting-docs/MIGRATION-v9-to-v10.md in full,
   including the "What to do after migration" workflow and the
   "Rollback" sub-section. Read $PACK/supporting-docs/INSTALL-PROCEDURES.md
   Procedure 5-C in full so you can drive reconciliation.
2. Create branch: git checkout -b migration-v9-to-v10
3. Run $PACK/scripts/migrate-v9-to-v10.sh end-to-end (non-interactive
   stages S0–S7). When it finishes, report:
   - the disposition summary line
     (e.g., "N pack-updates · M merges · K reconciliations needed")
   - the path to the generated migration report
   - the count and paths of any `.v9-customized` sidecars in the
     working tree
4. Read the migration report top to bottom and present its
   "Reconciliation required" section verbatim (or confirm empty),
   plus a summary of `git status` (modified + untracked).
   Do NOT commit.
5. Walk Procedure 5-C interactively, sidecar by sidecar. For each
   sidecar:
   a. State the file class (C1/C2/C3/D1/L1/L2/L3/S2/etc.), the
      sub-procedure that applies (5-C.1 through 5-C.8), and show
      the three-way diff path.
   b. For trinity files (5-C.2): execute the preamble step
      (remove `<!-- HOW TO USE THIS TEMPLATE -->` comment block,
      restore H1/intro from sidecar, replace `[PROJECT_NAME]`,
      `[PLATFORM_TARGETS]`, `[TRANSPORT]`, and other placeholders
      with the sidecar's filled-in values) BEFORE walking H2
      sections. Apply identically across CLAUDE.md / AGENTS.md /
      GEMINI.md.
   c. For PM-CHAT.md (5-C.3): execute the preamble step (remove
      HOW TO USE comment block and `*Copied from:*` italicized
      block) before reconciling project H1 / role / additional
      docs / remaining sections.
   d. For each H2 (or sub-section): present the project's
      pre-migration content from the sidecar and the v10 pack
      content side-by-side, then ask me to choose
      "keep pack / keep project / hand-merge / land in
      ## Project addenda or x-*.md". Apply the choice. For
      trinity, apply the same choice identically to all three
      files.
   e. After reconciling a file, delete its sidecar with `rm`.
      Confirm the file is gone.
6. After all sidecars are reconciled, run the inventory checks:
   - `find . -name '*.v9-customized' -not -path './.pack-migration-backup/*' -not -path './.git/*'`
     must be empty.
   - For trinity:
     `grep -nE '\[(PROJECT_NAME|PLATFORM_TARGETS|TRANSPORT|PLATFORM_DEFAULTS|PLATFORM_ARCHITECTURE|LANGUAGE_RULES|GRPC_RULES|PLATFORM_SECURITY|PLATFORM_TESTING|PLATFORM_ANTIPATTERNS)\]' CLAUDE.md AGENTS.md GEMINI.md`
     must be empty.
   - For PM-CHAT.md:
     `grep -n '\[PROJECT_NAME\]' docs/pack/PM-CHAT.md` must be
     empty.
   - Trinity rule check:
     `diff <(grep '^## ' CLAUDE.md) <(grep '^## ' AGENTS.md)`
     and the same for GEMINI.md must agree (modulo
     tool-intrinsic asymmetry).
   Report any check that fails and stop until I direct.
7. Run ./scripts/bootstrap.sh and ./scripts/validate.sh. If either
   fails, report and stop — do not commit a failing migration.
8. Present the final `git status` and a `git diff --stat`. Then
   ask me one question:
   "Approve commit, or rollback?"
   - On "commit": run `git add -A && git commit -m "feat: v10 — migrate from v9.3 (script + Procedure 5-C reconciliation)"`
     and report the commit hash. Then present the "Steps 5–7"
     instructions from MIGRATION-v9-to-v10.md so I can merge.
   - On "rollback": run the rollback commands from
     MIGRATION-v9-to-v10.md "Rollback" sub-section
     (`git checkout -- . && git clean -fd && rm -rf .pack-migration-backup && git checkout main && git branch -D migration-v9-to-v10`)
     and confirm `git status` is clean on `main`.

Rules:
- Do NOT commit anything before Step 8 approval. No intermediate
  commits. The migration is one atomic session.
- Do NOT modify any file starting with `x-` under any circumstance.
- Do NOT modify any file in the pack repo — only this project.
- For trinity reconciliation, every decision applies to all three
  files (CLAUDE.md / AGENTS.md / GEMINI.md). Never apply to one
  without applying to the other two.
- If the script errors or exits non-zero, report the stage, the
  sentinel files present under `.pack-migration-backup/v9.3-to-v10.0/`,
  and wait for direction. Do not attempt to recover by reversing
  individual file edits.
- If reconciliation reveals a defect in the pack scripts or docs
  that cannot be resolved by my decisions, stop and recommend
  rollback. The fix path is: rollback → fix the pack → `git pull`
  in the pack repo → re-run this prompt from clean v9.3.
```

Works on all three CLI tools (Claude Code, Codex, Gemini). On Claude
Desktop + filesystem MCP, the Desktop app can drive the script via
the same prompt with the MCP filesystem server enabled.
