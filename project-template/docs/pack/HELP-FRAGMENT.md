# Pack v11 — verb reference (this project)

Verb manifest for **this project**. Run `/pm-help` in your CLI, or
`bash scripts/pm-help.sh`, for this content. Full docs in `docs/pack/PM-CHAT.md`,
`docs/pack/INSTALL-PROCEDURES.md`, `docs/pack/OPTIONAL-FEATURES.md`.

## Project commands

| Verb | What it does |
|---|---|
| `/pm-startup` | Bootstrap a PM Chat session — sync repo, read state, run TD-TBD check, report. Run first in new sessions. |
| `/pm-help` | Print this fragment in your CLI. `bash scripts/pm-help.sh` is identical. |
| `/pm-status` | Quick project-state snapshot — repo state, live frontier, active modes, backlog, next queue. No sync, no full startup. |
| `/pm-refresh` | Re-warm live rules + PM-session state to the front of context mid-session. No sync, no history reset. |
| `/pm-dashboard` | Render the frontier dashboard, publish it to claude.ai in the foreground, and record its URL. |
| `/pm-review-mode` | Select how surfaced open items are presented — itemized / full / hybrid / none. |
| `/pm-intervention-mode` | Select the pause/surface gate posture — full / pre-coder / ambiguity / none. (Claude-only enforcement) |
| `/pm-isolation-mode` | Select which agent classes spawn into an isolated worktree — read-write-only / full. (Claude-only enforcement) |
| `/pm-groupings` | Query phase groupings — list / membership / deps / order / shared-with. Read-only. |
| `/pm-target-sweep` | Release-boundary target sweep — enumerate / overdue / re-encode-set / kind-set. Read-only. |
| `bash scripts/init-project.sh` | One-time setup. `--update` refreshes pack files non-destructively. |
| `bash scripts/migrate-v10-to-v11.sh` | One-time per upgrade. |
| `bash scripts/activate-capability.sh` | Activate a supported capability on this project — re-materializes its conditional files from `pack-capability-pool/`. |
| `bash scripts/target-sweep.sh <verb>` | Release-boundary target enumerations: enumerate / overdue / re-encode-set / kind-set (see docs/pack/PM-CHAT.md). |
| `bash scripts/groupings.sh <verb>` | Groupings queries: list / list-membership / deps [--deferral] / order / shared-with (see docs/pack/PM-CHAT.md). |
| `bash scripts/status-generate.sh` | Regenerate the STATUS.md dashboard's generated sections; `--check` gates drift. |
| `./agent-run.sh <cli> --agent <name>` | Spawn a project agent. `./agent-run.sh --help` for flags. |
| `bash scripts/pm-help.sh` | Print this fragment (LCD shell form). |

## See also

`docs/pack/PM-CHAT.md`, `docs/pack/METHODOLOGY.md`,
`docs/pack/PLATFORM-SKILLS.md`, `docs/pack/OPTIONAL-FEATURES.md`,
`docs/project/backlog/` (per-entry tree; `_toc.md` is the readable index).
