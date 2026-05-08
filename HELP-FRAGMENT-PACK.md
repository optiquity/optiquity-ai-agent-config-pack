# Pack v11 — verb reference (pack repo)

Verb manifest for the **pack repository**. Run `pack help` or `/pack-help`
in your CLI for this content. Full docs in `QUICKSTART.md`, `README.md`,
`PACK-CHAT.md`, `OPTIONAL-FEATURES.md`.

## Pack commands

| Verb | What it does |
|---|---|
| `/pack-startup` | Bootstrap a Pack Chat session — sync repo, read state, report. Run first in new sessions. |
| `/pack-help` | Print this fragment in your CLI. `pack help` shell verb is identical. |
| `claude --agent pack-architect` | Architecture / design pass on the pack. Read-only. |
| `claude --agent pack-planner` | Implementation planning — task breakdown, sequencing. |
| `claude --agent pack-reviewer` | Pre-commit review — trinity rule, doc consistency, validate-pack alignment. |
| `claude --agent pack-docs-researcher` | CLI / format / dependency verification against official docs. |
| `python3 scripts/validate-pack.py` | Pack structural validation. Required green before every commit. |
| `bash scripts/tests/<name>-test.sh` | Run an individual test suite. CI runs all. |
| `pack help` | Print this fragment (LCD shell verb). |

## Pack scripts (install / migrate / tracker)

| Script | What it does |
|---|---|
| `scripts/init-project.sh` | Bootstrap a Pack install in a new or existing project directory. Use `--update` to refresh an existing pack install in place. |
| `scripts/migrate-v9-to-v10.sh` | One-shot v9.3 → v10 migrator (frozen). Use against a v9.3 client repo. |
| `scripts/migrate-v10-to-v11.sh` | One-shot v10 → v11 migrator. Backup + BD-088 customization preserve + truthful report. |
| `scripts/restore-from-backup.sh` | Restore a v9.3 → v10 pre-migration tree (use the v11 migrator's printed `rsync` recipe for v11 backups). |
| `scripts/add-capability.sh` | Extend an existing project with an additional language/platform capability. |
| `scripts/pack-tracker.sh <subcmd>` | Tracker mode — `init`, `status`, `mirror-rebuild`, `disable`, `doctor`, `update-templates`, `enable-recommendations`. |
| `scripts/tracker-migrate.sh <subcmd>` | Tracker forward / reverse / status / doctor (lower-level wrapper). |

## Tracker commands (v11+)

[Included from `HELP-FRAGMENT-TRACKER.md` at pack root via `pack-help.sh`.]

## See also

`PACK-CHAT.md`, `PACK-AGENTS.md`, `OPTIONAL-FEATURES.md`, `BACKLOG.md`,
`CHANGELOG.md`.
