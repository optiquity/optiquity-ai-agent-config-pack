# Pack v11 — verb reference (this project)

Verb manifest for **this project**. Run `pack help` or `/pack-help` in
your CLI for this content. Full docs in `docs/pack/PM-CHAT.md`,
`docs/pack/INSTALL-PROCEDURES.md`, `docs/pack/OPTIONAL-FEATURES.md`.

## Project commands

| Verb | What it does |
|---|---|
| `/pm-startup` | Bootstrap a PM Chat session — sync repo, read state, run TD-TBD check, report. Run first in new sessions. |
| `/pack-help` | Print this fragment in your CLI. `pack help` shell verb is identical. |
| `bash scripts/init-project.sh` | One-time setup. `--update` refreshes pack files non-destructively. |
| `bash scripts/migrate-v10-to-v11.sh` | One-time per upgrade. The v9→v10 migrator is sunset. |
| `bash scripts/activate-capability.sh` | Activate a supported capability on this project — re-materializes its conditional files from `pack-capability-pool/`. |
| `./agent-run.sh <cli> --agent <name>` | Spawn a project agent. `./agent-run.sh --help` for flags. |
| `pack td promote --to=phase-N` | Promote a TD-NNN to a new phase epic (Path 1). |
| `pack td promote --to=phase-N.M` | Promote a TD-NNN to a new phase task under phase N (Path 2). |
| `pack td resolve <td-id>` | Direct-close wrapper. No promotion label; no new entity. |
| `pack help` | Print this fragment (LCD shell verb). |

## Tracker commands (deferred)

[Included from `HELP-FRAGMENT-TRACKER.md` in this directory via `pack-help.sh`.]
Tracker integration is deferred; the verbs refuse with a deferred message.

## See also

`docs/pack/PM-CHAT.md`, `docs/pack/METHODOLOGY.md`,
`docs/pack/PLATFORM-SKILLS.md`, `docs/pack/OPTIONAL-FEATURES.md`,
`docs/project/BACKLOG.md`.
