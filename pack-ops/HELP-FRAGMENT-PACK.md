# Pack v11 — verb reference (pack repo)

Verb manifest for the **pack repository**. Run `pack help` or `/pack-help`
in your CLI for this content. Full docs in `QUICKSTART.md`, `README.md`,
`pack-ops/PACK-CHAT.md`, `pack-ops/OPTIONAL-FEATURES.md`.

## Pack commands

| Verb | What it does |
|---|---|
| `/pack-startup` | Bootstrap a Pack Chat session — sync repo, read state, report. Run first in new sessions. |
| `/pack-refresh` | Reload the pack's live rules + session state to the front of context mid-session. No git pull, no history reset (distinct from `/pack-startup`). |
| `/pack-status` | Quick status snapshot — repo state, session frontier, current backlog item, next queued. Reads state files directly; no sync. |
| `/pack-help` | Print this fragment in your CLI. `pack help` shell verb is identical. |
| `/pack-dashboard` | Render and publish the pack frontier dashboard — a single-page HTML snapshot of live pack work and each item's pipeline. |
| `/pack-review-mode` | Set the review mode — how surfaced open items are presented (itemized / full / hybrid / none). |
| `/pack-intervention-mode` | Set the intervention mode — how much Pack Chat pauses at its gates (full / pre-coder / ambiguity / none). |
| `/pack-isolation-mode` | Set the isolation mode — which agent classes spawn into an isolated worktree (read-write-only / full). Claude-only selector; behavior in `pack-ops/OPERATING-MODES.md`. |
| `claude --agent pack-architect` | Architecture / design pass on the pack. Read-only. |
| `claude --agent pack-planner` | Implementation planning — task breakdown, sequencing. |
| `claude --agent pack-coder` | Implementation execution — writes/edits source per an approved plan, runs verification, produces a report. Never commits. |
| `claude --agent pack-reviewer` | Pre-commit review — trinity rule, doc consistency, validate-pack alignment. |
| `claude --agent pack-docs-researcher` | CLI / format / dependency verification against official docs. |
| `python3 scripts/validate-pack.py` | Pack structural validation. Required green before every commit. |
| `bash scripts/tests/<name>-test.sh` | Run an individual test suite. CI runs all. |
| `pack help` | Print this fragment (LCD shell verb; runs `scripts/pack-help.sh`). |

## Pack scripts (install / migrate)

| Script | What it does |
|---|---|
| `scripts/init-project.sh` | Bootstrap a Pack install in a new or existing project directory. Use `--update` to refresh an existing pack install in place. |
| `scripts/migrate-v10-to-v11.sh` | One-shot v10 → v11 migrator. Backup + BD-088 customization preserve + truthful report. |
| `scripts/dry-run-migration.sh` | Read-only migration dry-run harness. Clones target into `/tmp`, runs the appropriate per-version migrator with `--dry-run`, captures the full diff. Three modes: synthetic fixture / git URL / local-path. Used as the v11+ release-gate harness; safe for any v10 client. |
| `scripts/restore-from-backup.sh` | Restore a v9.3 → v10 pre-migration tree (use the v11 migrator's printed `rsync` recipe for v11 backups). |
| `scripts/add-capability.sh` | Extend an existing project with an additional language/platform capability. |
| `scripts/install-graphify-hook.sh` | Install the Graphify pre-push graph-refresh hook into this clone's git hooks dir. One-time, per-clone, idempotent. |

## See also

`pack-ops/PACK-CHAT.md`, `pack-ops/PACK-AGENTS.md`, `pack-ops/OPTIONAL-FEATURES.md`, the `/backlog/` tree,
the `/changelog/` tree.
