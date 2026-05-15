# Tracker commands (v11+)

Tracker mode opts the surface into GH Issues as the source of truth.
The flat files become read-only mirrors. Reversible — `pack tracker
disable` restores flat-file mode.

| Verb | What it does |
|---|---|
| `pack tracker init` | Opt-in: write `tracker.toml`, validate `gh auth`, ensure labels, run forward migration. |
| `pack tracker status` | One-screen view of tracker state (mode, repo, mapping, freshness). Read-only. |
| `pack tracker disable` | Reverse migration; flip back to flat-file. Atomic — restores backup on failure. |
| `pack tracker doctor` | Validate config, mapping, mirror, templates, capability cache. Surfaces typed errors. |
| `pack tracker mirror-rebuild` | Refresh BACKLOG.md mirror header without re-running forward migration. |
| `pack tracker update-templates` | Apply translation rules to upgrade entries to current `template_version`. |
| `pack tracker enable-recommendations` | Clear "don't ask again" so recommendations re-evaluate at next session. |

## TD promotion (v11+)

`pack td <verb>` orchestrates the V3.3 §3 two-path TD promotion + the
direct-close shape. The `pack td promote` entries below are also listed
under "Project commands" in `HELP-FRAGMENT.md` (LCD shell verb surface);
this fragment adds the `resolve` direct-close wrapper and the colloquial
mappings.

| Verb | What it does |
|---|---|
| `pack td promote --to=phase-N <td-id>` | Path 1 — promote TD to a new phase epic (V3.3 §3.3). PM Chat invokes architect by default per §7.2. |
| `pack td promote --to=phase-N.M <td-id>` | Path 2 — promote TD to a new phase task under phase N (V3.3 §3.4). Wires `Dependencies` bullets to cross-entity `blocked-by` edges per §5.1. |
| `pack td resolve <td-id> [--note "..."]` | Direct close (V3.3 §3.2). No promotion label; no new entity. |

Path 3 is forbidden per V3.3 §1 supersession + §3 line 27. There is
no `--fold-into` flag.

## Colloquial mappings

| Phrase | Verb |
|---|---|
| "set up the tracker" / "enable issue tracking" | `pack tracker init` |
| "switch back to flat files" / "turn off the tracker" | `pack tracker disable` |
| "tracker doctor" / "are we good?" | `pack tracker doctor` |
| "tracker status" / "what's the tracker doing?" | `pack tracker status` |
| "upgrade the templates" / "templates are stale" | `pack tracker update-templates` |
| "rebuild the mirror" / "regenerate BACKLOG.md" | `pack tracker mirror-rebuild` |
| "remind me about the tracker again" | `pack tracker enable-recommendations` |
| "promote this TD to a new phase" / "make a phase out of this" | `pack td promote --to=phase-N <td-id>` (Path 1) |
| "promote this TD to a task in phase N" / "add as a task under phase N" | `pack td promote --to=phase-N.M <td-id>` (Path 2) |
| "close this TD inline" / "this TD is small, just close it" | `pack td resolve <td-id>` (direct close) |

See the tracker example template (`tracker.toml.pack-example` in the pack repo, or `tracker.toml.example` at a client project root) and `OPTIONAL-FEATURES.md` for full setup.
