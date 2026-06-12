# Tracker commands (v11+)

Tracker mode opts the surface into GH Issues as the source of truth.
The flat files become read-only mirrors. Reversible — `pack tracker
disable` restores flat-file mode.

| Verb | What it does |
|---|---|
| `pack tracker init` | Opt-in: write `tracker.toml`, validate `gh auth`, ensure labels, run forward migration. (Pack repo: the file is local + gitignored — your checkout only; the repo always ships flat-file.) |
| `pack tracker status` | One-screen view of tracker state (mode, repo, mapping, freshness). Read-only. |
| `pack tracker disable` | Reverse migration; flip back to flat-file. Atomic — restores backup on failure. |
| `pack tracker doctor` | Validate config, mapping, tree/mirror freshness, status coherence, templates, capability cache. Surfaces typed errors. |
| `pack tracker tree-rebuild` | Pack repo: regenerate the `/backlog/` tree + `_toc.md` from tracker state — one-way, no mode flip; hand-edits are overwritten without detection. |
| `pack tracker edit` | Pack repo (tracker mode): edit a tracked entry against the tracker SSOT — status flips, field/body edits. |
| `pack tracker new-entry` | Pack repo (tracker mode): create a new tracked BD entry from a verbatim entry-span file, then rebuild the tree. |
| `pack tracker mirror-rebuild` | Client surface only: refresh the BACKLOG.md mirror header without re-running forward migration. On the pack surface this fails loud — use `pack tracker tree-rebuild`. |
| `pack tracker update-templates` | Apply translation rules to upgrade entries to current `template_version`. |
| `pack tracker enable-recommendations` | Clear "don't ask again" so recommendations re-evaluate at next session. |

## TD promotion (v11+)

`pack td <verb>` orchestrates the two-path TD promotion + the
direct-close shape. The `pack td promote` entries below are also listed
under "Project commands" in `HELP-FRAGMENT.md` (LCD shell verb surface);
this fragment adds the `resolve` direct-close wrapper and the colloquial
mappings.

| Verb | What it does |
|---|---|
| `pack td promote --to=phase-N <td-id>` | Path 1 — promote TD to a new phase epic. PM Chat invokes architect by default. |
| `pack td promote --to=phase-N.M <td-id>` | Path 2 — promote TD to a new phase task under phase N. Wires `Dependencies` bullets to cross-entity `blocked-by` edges. |
| `pack td resolve <td-id> [--note "..."]` | Direct close. No promotion label; no new entity. |

Path 3 is forbidden. There is
no `--fold-into` flag.

## Colloquial mappings

| Phrase | Verb |
|---|---|
| "set up the tracker" / "enable issue tracking" | `pack tracker init` |
| "switch back to flat files" / "turn off the tracker" | `pack tracker disable` |
| "tracker doctor" / "are we good?" | `pack tracker doctor` |
| "tracker status" / "what's the tracker doing?" | `pack tracker status` |
| "upgrade the templates" / "templates are stale" | `pack tracker update-templates` |
| "rebuild the tree" / "regenerate the backlog tree" | `pack tracker tree-rebuild` (pack repo) |
| "rebuild the mirror" / "regenerate BACKLOG.md" | `pack tracker mirror-rebuild` (client surface; the pack repo has no mirror — use `tree-rebuild`) |
| "remind me about the tracker again" | `pack tracker enable-recommendations` |
| "promote this TD to a new phase" / "make a phase out of this" | `pack td promote --to=phase-N <td-id>` (Path 1) |
| "promote this TD to a task in phase N" / "add as a task under phase N" | `pack td promote --to=phase-N.M <td-id>` (Path 2) |
| "close this TD inline" / "this TD is small, just close it" | `pack td resolve <td-id>` (direct close) |

See the tracker example template (`tracker.toml.pack-example` in the pack repo, or `tracker.toml.example` at a client project root) and `OPTIONAL-FEATURES.md` for full setup.
