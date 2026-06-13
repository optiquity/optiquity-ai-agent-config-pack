# Tracker commands (deferred)

Tracker (GH Issues) integration is **deferred indefinitely, with no
release version** (BD-214). **Flat-file per-entry is the sole supported
mode.** The `pack tracker` verbs below refuse with a deferred message;
the tracker code is retained dormant and test-covered for a future
resumption.

| Verb | What it does |
|---|---|
| `pack tracker init` | DEFERRED — refuses with a deferred message; flat-file is the supported mode. |
| `pack tracker status` | DEFERRED — refuses; no tracker state exists in flat-file mode. |
| `pack tracker disable` | DEFERRED — there is no tracker mode to disable; flat-file is already the mode. |
| `pack tracker doctor` | DEFERRED — refuses; nothing to validate in flat-file mode. |
| `pack tracker tree-rebuild` | DEFERRED — refuses; the flat-file tree is hand-maintained, not rebuilt from a tracker. |
| `pack tracker edit` | DEFERRED — refuses; edit the per-entry `BD-NNN.md` file directly. |
| `pack tracker new-entry` | DEFERRED — refuses; author the per-entry `BD-NNN.md` file directly. |
| `pack tracker mirror-rebuild` | DEFERRED — refuses; there is no mirror. |
| `pack tracker update-templates` | DEFERRED — refuses. |
| `pack tracker enable-recommendations` | DEFERRED — refuses; the recommendation system is dormant. |

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

The tracker phrases below map to verbs that are DEFERRED (BD-214) — each
refuses with a deferred message; flat-file is the supported mode.

| Phrase | Verb |
|---|---|
| "set up the tracker" / "enable issue tracking" | `pack tracker init` (deferred) |
| "switch back to flat files" / "turn off the tracker" | `pack tracker disable` (deferred) |
| "tracker doctor" / "are we good?" | `pack tracker doctor` (deferred) |
| "tracker status" / "what's the tracker doing?" | `pack tracker status` (deferred) |
| "upgrade the templates" / "templates are stale" | `pack tracker update-templates` (deferred) |
| "rebuild the tree" / "regenerate the backlog tree" | `pack tracker tree-rebuild` (deferred) |
| "rebuild the mirror" / "regenerate BACKLOG.md" | `pack tracker mirror-rebuild` (deferred) |
| "remind me about the tracker again" | `pack tracker enable-recommendations` (deferred) |
| "promote this TD to a new phase" / "make a phase out of this" | `pack td promote --to=phase-N <td-id>` (Path 1) |
| "promote this TD to a task in phase N" / "add as a task under phase N" | `pack td promote --to=phase-N.M <td-id>` (Path 2) |
| "close this TD inline" / "this TD is small, just close it" | `pack td resolve <td-id>` (direct close) |
