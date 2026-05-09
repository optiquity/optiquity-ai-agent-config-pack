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

See the tracker example template (`tracker.toml.pack-example` in the pack repo, or `tracker.toml.example` at a client project root) and `OPTIONAL-FEATURES.md` for full setup.
