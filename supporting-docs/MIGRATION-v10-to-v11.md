# Migrating from v10 to v11

This guide is the authoritative narrative for upgrading an existing
**v10**-pack-configured project to **v11**. Two phases:

1. **Phase A — forced v10→v11 changes.** Everyone runs this. Trinity
   refresh, HELP-FRAGMENT install, per-CLI `pack-help` surfaces,
   `tracker.toml.example`, issue templates, BD-042 doc relocation
   tail. Driven by `scripts/migrate-v10-to-v11.sh` (BD-085).
2. **Phase B — optional tracker opt-in.** Per surface, per user. Run
   only if you want to move issue tracking out of `BACKLOG.md` /
   `STATUS.md` flat files into GitHub Issues. Driven by
   `pack tracker init` (post-migration).

If you're on **v9.x or earlier**, the v9->v10 migrator was sunset
in v11 (BD-121); v9 is no longer supported. Reach out to the pack
maintainer for migration guidance, or recover the legacy migrator
from history with
`git -C "$PACK" checkout v10 -- scripts/migrate-v9-to-v10.sh
supporting-docs/MIGRATION-v9-to-v10.md`.

If you're managing **multiple projects**, repeat the whole flow per
project — there is no shared state between projects.

---

## What changed in v11

**Forced (Phase A):**

- New help-verb system: `pack help` (LCD shell verb) and `/pack-help`
  (per-CLI command). Both invoke `scripts/pack-help.sh` which renders
  `HELP-FRAGMENT-PACK.md` (pack repo) or `docs/pack/HELP-FRAGMENT.md`
  (client repo) with the shared `HELP-FRAGMENT-TRACKER.md` inlined.
- New trinity addenda: `## Quick reference` block at the top of every
  trinity file (pack-root + client) — one line for `pack help` /
  `/pack-help`, one line for `pack-startup` / `pm-startup` recommended
  first action.
- BD-088 customization-preservation contract: `init-project.sh --update`
  and `migrate-v10-to-v11.sh` share one library and one truthful
  report format. See `MERGE-STRATEGY.md` for the per-file class matrix.
- BD-042 relocation tail: any v9-era reference docs still at project
  root (`METHODOLOGY.md`, `PROMPT-TEMPLATES.md`, etc.) are moved to
  `docs/pack/` (with `git mv` when tracked, sidecared otherwise).
- Issue template forms (`.github/ISSUE_TEMPLATE/work-item.yml`,
  `inbound.yml`, `config.yml`) installed for projects opting into
  GitHub Issues.
- `tracker.toml.example` installed at project root (template for
  Phase B).

**Optional (Phase B):**

- TrackerProvider abstraction (V1 §2.1): 18 ops + raw + capabilities,
  one canonical implementation against `gh`. Future backends
  (forgejo / linear / jira) plug in without touching callers.
- Forward migration `BACKLOG.md` → GitHub Issues (V1 §6.2),
  reverse migration GitHub Issues → `BACKLOG.md` sidecar (V1 §6.5).
  Both idempotent.
- Inflection-point recommendation system (D-19): pack-startup /
  pm-startup observe pack/project signals (BD count, BACKLOG size,
  growth rate) and recommend tracker opt-in when threshold heuristics
  fire. Per-user state persisted under `.pack-tracker/`.
- TrackerProvider abstraction consumed by PM chat / Pack chat for
  tracker-aware prompts. The dedicated `auditor-issue-tracking` agent
  (BD-109 client-side, BD-110 pack-side) is on the v11.x roadmap; the
  provider it consumes ships in v11.0.

**Out of scope for this version:**

- Multi-tracker (Linear / Jira / Forgejo) backends — the abstraction
  exists, only `gh` is implemented in v11.
- `--dry-run` / `--apply` / `--resume` migrator modes — single-shot
  only in v11; BD-095 will extend.

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

---

## Step 1 — Run the migration script

```sh
PACK=/path/to/pack-repo bash scripts/migrate-v10-to-v11.sh
```

Default target is the current directory; pass an explicit path as the
last argument if needed.

The script runs 7 stages:

| Stage | What it does |
|---|---|
| S0 | Pre-flight (pack valid, BD-088 lib present, target git, clean tree, v10-shaped, v10 tag resolves) |
| S1 | Backup — full working tree (excludes `.git/` + state dirs) into `.pack-migrate-v10-to-v11-backup/` |
| S2 | Initialize BD-088 customization-preserve state |
| S3 | Dispatch v10 → v11 changes via BD-088 (trinity / configs / scripts / agents / docs) |
| S4 | BD-042 relocation tail (legacy root docs → `docs/pack/`) |
| S5 | Install v11 client artifacts (HELP-FRAGMENT*.md, tracker.toml.example, issue forms, per-CLI pack-help) |
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
| 15 | BD-088 library missing under pack | The pack repo is corrupt or incomplete; re-clone. |
| 21–30 | Stage `S<n>` failure | Read the printed error message; address; retry. |

---

## Step 2 — Review the migration report

```sh
less .pack-migrate-v10-to-v11/report.md
```

The report is **truthful** (BD-059 / BD-088 contract): every file the
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

# If you have a Claude Code / Codex / Gemini install:
ls .claude/skills/pack-help/SKILL.md \
   .codex/skills/pack-help/SKILL.md \
   .gemini/commands/pack-help.toml
# All three should exist.
```

Run a Pack Chat session: `/pm-startup` should now report v11 as the
active pack version and read in the new `## Quick reference` blocks.

---

## Step 4 — Commit

```sh
git add -A
git diff --staged | less
# Sanity-check the diff. Highlights:
#   - CLAUDE.md / AGENTS.md / GEMINI.md gained a "## Quick reference"
#     block (or a fresh template if you had no customizations).
#   - .gitignore may have been merged with new pack additions.
#   - docs/pack/HELP-FRAGMENT.md and docs/pack/HELP-FRAGMENT-TRACKER.md
#     are new.
#   - tracker.toml.example is new at project root.
#   - .github/ISSUE_TEMPLATE/{work-item,inbound,config}.yml are new.
#   - per-CLI pack-help skill / command are new.
#   - Any reconciliation files you edited.

git commit -m "chore: migrate to AI Agent Config Pack v11"
```

---

## Step 5 — Phase B (optional) — Tracker opt-in

If you want to move issue tracking out of `BACKLOG.md` flat-file format
into GitHub Issues, run the tracker opt-in flow:

```sh
bash scripts/pack-tracker.sh init
```

This is **per-surface, per-user**. It is NOT done by `migrate-v10-to-v11.sh`
because the choice is a deliberate one — many projects prefer flat-file
tracking (visible in `git log`, no GitHub round-trip) and v11 ships
fully without ever opting in.

`pack-tracker.sh init` will:

1. Read `tracker.toml.example` at project root and prompt you for
   provider config (default: `gh`).
2. Create `tracker.toml` with your settings.
3. Optionally run `forward` migration: `BACKLOG.md` entries become
   GitHub Issues with the `bd:NNN` label.
4. Add a `.pack-tracker/state` directory for sidecar tracking-state.

To opt out later: `bash scripts/pack-tracker.sh disable` (idempotent;
runs the reverse migration internally).

To check tracker health: `bash scripts/pack-tracker.sh doctor`.

For verbs: `bash scripts/pack-help.sh` shows the full tracker command
surface.

---

## BD-059 lessons learned — customization preservation

The historical v10 migrator (the v9->v10 script, sunset in v11 per
BD-121) had a defect class that
silently destroyed project customizations on a small set of file
shapes (BD-059 in the BACKLOG). v11 fixes this with the BD-088
library:

1. **Truthful report.** Every file the migrator touches appears in
   exactly one section of `report.md`. No silent drops.
2. **Per-class strategies.** 12 classes covering trinity (3-way merge),
   structured configs (JSON/TOML allowlist), env files (KEY-union),
   per-CLI agents (`x-` reserved-prefix preservation), pack-shipped
   scripts (3-way text), and so on. See `MERGE-STRATEGY.md`.
3. **Single-slot sidecars.** `<file>.v10-customized` for the migrator,
   `<file>.pre-update` for `init-project.sh --update`. The migrator
   refuses to run when its backup directory already exists; `--update`
   refuses when prior `.pre-update` sidecars are present. Both gates
   prevent silent overwrites.
4. **CI regression guard.** validate-pack Check 25 (BD-089) runs a
   4-fixture synthetic on every push to fail-closed if BD-088
   regresses. Class-coverage delegated to
   `scripts/tests/test-customization-preserve.sh` which CI runs per
   BD-083.

If the migrator reports `customization-detected-needs-reconciliation`
on a file you didn't customize, that's a defect — please file a BD
against the `customize-preserve` library with the
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
  are preserved unchanged (BD-088 `claude-settings` allowlist).

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

### My customizations weren't preserved (BD-059 class regression)

This should never happen for the 12 documented classes (`MERGE-STRATEGY.md`).
If it does:

1. Save `dispositions.tsv` and the relevant `<file>.v10-customized`.
2. File a BD with the disposition row + the file's pre-migration content.
3. Restore from backup (Rollback section above).
4. Wait for the BD to land before re-attempting.

Validate-pack Check 25 + `test-customization-preserve.sh` are the CI
guards against this; if either is silenced or removed, BD-059 class
defects can re-emerge.

---

## What to do after migration

1. **Read the `## Quick reference` block** at the top of each trinity
   file. The pack-startup / pm-startup recommendation is the documented
   first action for new sessions.
2. **Decide on Phase B.** If your project's BD volume is moderate
   (< 50 open) and BACKLOG.md is comfortable, stay flat-file. If
   you're juggling many cross-references, GitHub linking would help,
   or you want CI to gate on tracker hygiene, opt in. Recommendation:
   pack-startup will prompt you when its heuristics fire.
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
