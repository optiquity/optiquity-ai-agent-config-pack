# Pack v11 — verb reference (pack repo)

Verb manifest for the **pack repository**. Run `pack help` or `/pack-help`
in your CLI for this content. Full docs in `QUICKSTART.md`, `README.md`,
`pack-ops/PACK-CHAT.md`, `pack-ops/OPTIONAL-FEATURES.md`.

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
| `scripts/migrate-v10-to-v11.sh` | One-shot v10 → v11 migrator. Backup + BD-088 customization preserve + truthful report. |
| `scripts/dry-run-migration.sh` | Read-only migration dry-run harness. Clones target into `/tmp`, runs the appropriate per-version migrator with `--dry-run`, captures the full diff. Three modes: synthetic fixture / git URL / local-path. Used as the v11+ release-gate harness; safe for any v10 client. |
| `scripts/restore-from-backup.sh` | Restore a v9.3 → v10 pre-migration tree (use the v11 migrator's printed `rsync` recipe for v11 backups). |
| `scripts/add-capability.sh` | Extend an existing project with an additional language/platform capability. |
| `scripts/pack-tracker.sh <subcmd>` | Tracker mode — `init`, `status`, `tree-rebuild`, `edit`, `new-entry`, `mirror-rebuild`, `disable`, `doctor`, `update-templates`, `enable-recommendations`. |
| `scripts/pack-td.sh <subcmd>` | TD orchestration — `promote --to=phase-N` (Path 1), `promote --to=phase-N.M` (Path 2), `resolve` (direct close per V3.3 §3.2). |
| `scripts/tracker-migrate.sh <subcmd>` | Tracker forward / reverse / status / doctor (lower-level wrapper). |

## Tracker commands (v11+)

[Included from `pack-ops/HELP-FRAGMENT-TRACKER.md` via `scripts/pack-help.sh`.]

## See also

`pack-ops/PACK-CHAT.md`, `pack-ops/PACK-AGENTS.md`, `pack-ops/OPTIONAL-FEATURES.md`, the `/backlog/` tree,
the `/changelog/` tree.
