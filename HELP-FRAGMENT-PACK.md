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

## Tracker commands (v11+)

[Included from `HELP-FRAGMENT-TRACKER.md` at pack root via `pack-help.sh`.]

## See also

`PACK-CHAT.md`, `PACK-AGENTS.md`, `OPTIONAL-FEATURES.md`, `BACKLOG.md`,
`CHANGELOG.md`.
