# Pack v11 — verb reference (this project)

This is the verb manifest for **this project** — the verbs used
when developing software with the Optiquity AI Agent Config Pack
installed. For interactive help: run `pack help` or `/pack-help`
in your CLI.

For full documentation see `docs/pack/QUICKSTART.md`,
`docs/pack/PM-CHAT.md`, `docs/pack/INSTALL-PROCEDURES.md`, and
`docs/pack/OPTIONAL-FEATURES.md`.

## Project commands (this surface)

### PM Chat session

| Verb | What it does |
|---|---|
| `/pm-startup` | Bootstrap a PM Chat session — sync repo, read BACKLOG / STATUS / PM-CHAT / PLATFORM-SKILLS, identify current phase, run TD-TBD sentinel check, report state. Run first in any new or compacted session. |
| `/pack-help` | Print this fragment in your CLI (Claude Code skill / Codex skill / Gemini command). The `pack help` shell verb prints the same content. |

### Project install / migrate / extend

| Verb | What it does |
|---|---|
| `bash scripts/init-project.sh` | One-time setup. Stages pack files into a new or existing project tree (the `--update` form refreshes pack files non-destructively). |
| `bash scripts/migrate-v9-to-v10.sh` | One-time per upgrade. Migrate a v9.3 project up to v10. (A v10→v11 migration script ships separately when v11 release is cut.) |
| `bash scripts/add-capability.sh` | Add a pack-supported capability (e.g. another language / platform / protocol) to an already-initialized project. |
| `python3 scripts/merge-platform-skills.py` | Splice helper for `PLATFORM-SKILLS.md` updates during install / upgrade. |
| `python3 scripts/merge-trinity.py` | Splice helper for trinity-file (`CLAUDE.md` / `AGENTS.md` / `GEMINI.md`) updates during install / upgrade. |

### Per-agent execution

| Verb | What it does |
|---|---|
| `./agent-run.sh <cli> --agent <name>` | Spawn a project agent (architect / coder / reviewer / tester / auditor / etc.) with the right read-only / write flags for the chosen CLI. Run `./agent-run.sh --help` for the full flag list. |

### Discoverability

| Verb | What it does |
|---|---|
| `pack help` | Print this fragment (LCD shell verb; identical content to `/pack-help`). |

## Tracker commands (v11+)

[Included from `HELP-FRAGMENT-TRACKER.md` in this directory via `pack-help.sh`.]

## See also

- `docs/pack/QUICKSTART.md` — full setup and quick walkthrough.
- `docs/pack/PM-CHAT.md` — PM Chat operating rules.
- `docs/pack/METHODOLOGY.md` — pack methodology reference.
- `docs/pack/PLATFORM-SKILLS.md` — skill-selection matrix for this project.
- `docs/pack/OPTIONAL-FEATURES.md` — per-CLI optional features and tracker walkthrough.
- `BACKLOG.md` (or `docs/project/BACKLOG.md`) — open TD-NNN items.
