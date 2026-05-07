# Pack v11 — verb reference (pack repo)

This is the verb manifest for the **pack repository** itself —
the verbs used when developing the Optiquity AI Agent Config Pack.
For interactive help: run `pack help` or `/pack-help` in your CLI.

For full documentation see `QUICKSTART.md`, `README.md`,
`PACK-CHAT.md`, and `OPTIONAL-FEATURES.md`.

## Pack commands (this surface)

### Pack Chat session

| Verb | What it does |
|---|---|
| `/pack-startup` | Bootstrap a Pack Chat session — sync repo, read `BACKLOG.md` / `CHANGELOG.md` / `README.md` / `PACK-CHAT.md`, check CI tooling, report state. Run first in any new or compacted session. |
| `/pack-help` | Print this fragment in your CLI (Claude Code skill / Codex skill / Gemini command). The `pack help` shell verb prints the same content. |

### Pack-development agents

Pack agents are spawned via the host CLI directly — they are
session-scoped and do not require `agent-run.sh`.

| Verb | What it does |
|---|---|
| `claude --agent pack-architect` | Architecture / design pass on the pack itself. Read-only analysis + recommendations. |
| `claude --agent pack-planner` | Implementation planning — task breakdown, file dependency analysis, commit sequencing. |
| `claude --agent pack-reviewer` | Review pack changes pre-commit — trinity rule compliance, stale cross-references, doc consistency, validate-pack alignment. |
| `claude --agent pack-docs-researcher` | CLI tool / file-format / dependency verification against official docs. |

### Pack repository tooling

| Verb | What it does |
|---|---|
| `python3 scripts/validate-pack.py` | Run the pack's structural validation checks. Required green before every commit. |
| `bash scripts/tests/<name>-test.sh` | Run an individual test suite. The `Validate Pack` GitHub workflow runs all suites on every push. |
| `pack help` | Print this fragment (LCD shell verb; identical content to `/pack-help`). |

## Tracker commands (v11+)

[Included from `HELP-FRAGMENT-TRACKER.md` at pack root via `pack-help.sh`.]

## See also

- `QUICKSTART.md` — full setup and quick walkthrough.
- `README.md` — repository layout and version history.
- `PACK-CHAT.md` — Pack Chat operating rules.
- `PACK-AGENTS.md` — agent routing table for pack-development work.
- `OPTIONAL-FEATURES.md` — per-CLI optional features and tracker walkthrough.
- `BACKLOG.md` — open BD-NNN items.
- `CHANGELOG.md` — version history details.
