# Tracker commands (v11+)

Tracker mode opts the surface into GH Issues as the source of truth for
BACKLOG / STATUS / IMPLEMENTATION_PLAN / CHANGELOG. The flat files
become read-only mirrors. Every tracker verb is reversible — running
`pack tracker disable` restores the flat-file source of truth.

| Verb | What it does |
|---|---|
| `pack tracker init` | Opt-in to tracker mode. Writes `tracker.toml`, validates `gh auth`, ensures the canonical label set, and runs the forward migration. ~3–5 min the first time. |
| `pack tracker status` | One-screen view of tracker state — mode, backend, repo, mapping count, mirror freshness, template freshness, last forward run, last reverse run. Read-only. |
| `pack tracker disable` | Reverse migration + flip mode back to flat-file. Atomic — if any step fails the original flat files are restored from backup. |
| `pack tracker doctor` | Validate `tracker.toml` schema, mapping integrity, mirror freshness, template freshness, capability cache. Surfaces typed errors with recovery verbs. |
| `pack tracker mirror-rebuild` | Refresh the BACKLOG.md mirror header without re-running the full forward migration. Use when the mirror is stale but the mapping is current. |
| `pack tracker update-templates` | Apply template-version translation rules to upgrade entries from an older `template_version` to the current one. `--dry-run` previews; `--apply` writes. |
| `pack tracker enable-recommendations` | Clears a prior "don't ask again" so the chat re-evaluates inflection-point signals at the next session start. |

## Colloquial mappings (chat recognizes these phrases)

| Phrase | Verb |
|---|---|
| "set up the tracker" / "switch to GH Issues" / "enable issue tracking" | `pack tracker init` |
| "switch back to flat files" / "turn off the tracker" / "go back to BACKLOG.md" | `pack tracker disable` |
| "check tracker health" / "tracker doctor" / "are we good?" | `pack tracker doctor` |
| "tracker status" / "what's the tracker doing?" / "are we on the tracker?" | `pack tracker status` |
| "upgrade the templates" / "templates are stale" / "fix template versions" | `pack tracker update-templates` |
| "rebuild the mirror" / "regenerate BACKLOG.md" / "the mirror is wrong" | `pack tracker mirror-rebuild` |
| "remind me about the tracker again" / "re-enable recommendations" | `pack tracker enable-recommendations` |

## Underlying script

The `pack tracker` verbs are thin wrappers around `scripts/tracker-migrate.sh`
(forward / reverse / status / doctor) and `scripts/pack-tracker.sh` (the
verb dispatcher). Either can be invoked directly when scripting.

## See also

- `tracker.toml.example` — annotated config schema (V1 §3.1).
- `OPTIONAL-FEATURES.md` — full tracker walkthrough.
- `PACK-CHAT.md` / `PM-CHAT.md` — chat operating instructions including
  the full colloquial-routing table.
