# Operating modes — review / intervention / isolation

Self-contained SSOT for the pack's three operating-mode families. Pack Chat
(the orchestrator) applies the active modes; spawned agents never read the
config — mode-dependent directives are injected into each spawn prompt by the
orchestrator. Modes govern Pack Chat only.

## The three families

### Review mode — `review_mode` (default `itemized`)

Governs how the user is asked to respond to the open items (questions, gaps,
expansions, decisions) that spawned agents surface in their reports.

| Value | Behavior |
|---|---|
| `itemized` (default) | Walk the open items one at a time. Per item: (1) enough context to understand the problem; (2) the agent's options (not the chat's); (3) the agent's recommendation only if it is evidence/logic-based, else state that none can be given. Exclude memory-based recommendations and any that defer/delay work to another or a new BD. This is current behavior. |
| `full` | Present all open items together in a single batch, each with as much detail as needed and the agent's evidence/logic-based recommendation (or an explicit "no recommendation"). Same memory/defer exclusion. |
| `hybrid` | Present the open items in multiple batches grouped by complexity — simple items batched together, complex items shown individually — each with full detail and the agent's evidence/logic-based recommendation. Same memory/defer exclusion. |
| `none` | No user review. For every surfaced open item the agent's evidence/logic-based recommendation is auto-accepted. Coupled to `none` intervention; shows an explicit risk warning at selection. Safe only because every agent recommendation must exist and be reliable (`[rationale: open-item-surfacing]`). |

### Intervention mode — `intervention_mode` (default `full`)

Governs the pause / surface gates — the commit-approval gate, the reviewer-
triage gate, the planner-to-coder gate, and the design-review gate.

| Value | Behavior |
|---|---|
| `full` (default) | Every gate pauses for explicit user input. This is current behavior. |
| `pre-coder` | Pauses at the pre-implementation gates (design review, planner-to-coder), then runs the coder → reviewer/fix cycle (fix-all) uninterrupted — pausing again only if an unplanned architect pass is needed, or the pipeline must stop / divert / reprioritize unplanned or later work. At other gates Pack Chat accepts the agent's evidence-or-logic recommendation. The commit-approval gate still pauses (only `none` waives it, per the safety boundary). |
| `ambiguity` | Pack Chat accepts the agent's evidence-or-logic recommendation at every gate EXCEPT where the agent surfaces genuine ambiguity (no reliable recommendation), which pauses for the user. The commit-approval gate still pauses. |
| `none` | No pause / surface gate; Pack Chat accepts every agent recommendation and auto-commits (see the safety boundary). |

### Isolation mode — `isolation_mode` (default `read-write-only`, Claude-only)

Governs which agent classes spawn into an isolated worktree. Worktree
isolation is a Claude-only capability, so this family is Claude-only.

| Value | Behavior |
|---|---|
| `read-write-only` (default) | Only read-write agents (coders, fix-coders) spawn into an isolated worktree; read-only agents (reviewers, architects, planners, docs-researchers) spawn in the tree the work lives in. This is current behavior. |
| `full` | All agents (read-only included) spawn into an isolated worktree, then `cd` to the target tree. |

## Coupling — `none` ↔ `none`

Writing `review_mode: none` also sets `intervention_mode: none`, and writing
`intervention_mode: none` also sets `review_mode: none`. The two `none` states
are always paired — an unreviewed finding auto-applied under one family cannot
land while the other family still gates.

## Safety boundary — `none` intervention

`none` intervention authorizes Pack Chat auto-commit — a standing user-granted
override of the per-commit approval gate. Pack Chat NEVER auto-pushes. Spawned
agents NEVER commit, in every mode — that boundary is absolute
(`[rationale: agents-never-commit]`).

## The config — `pack-ops/session-config.json`

A gitignored, per-clone (per-worktree when a clone has multiple working trees),
orchestrator-read-only sibling of `pack-ops/session-state.json`. Schema
`pack-session-config/1`; three string
fields, each with a default:

```json
{
  "schema": "pack-session-config/1",
  "review_mode": "itemized",
  "intervention_mode": "full",
  "isolation_mode": "read-write-only"
}
```

- **Missing / absent / malformed ⇒ defaults** — never an error, never a random
  value. The three defaults (`itemized` / `full` / `read-write-only`) equal
  current Pack-Chat behavior, so an unset config behaves as today.
- **Orchestrator-read-only** — read ONLY by Pack Chat (the main tree); spawned
  agents never read it, so its absence in an isolated worktree is harmless by
  construction.
- **Not git-tracked** — so no CI check validates its content; the orchestrator
  validates at read time (missing / malformed ⇒ defaults).

## Reading the config

Re-read the active mode at each point it governs a decision — never a session-
start-cached value. A cached read can drift across context compaction, a long
session, or a background-session worktree, spawning agents under the wrong mode
(a silent correctness failure). Read-at-point-of-use holds nothing between disk
and decision, so nothing can drift. It extends the "verify at runtime, never
trust settings" discipline to the orchestrator's config read.

Resolve the config at the CURRENT worktree — the checkout Pack Chat runs in
(the main checkout in a single-worktree clone, or the active linked dev
worktree). Derive the path at runtime from `git rev-parse --show-toplevel`;
read one field, folding absent / malformed / unreachable to the family default:

```bash
# Resolve the current-worktree config path
cfg="$(git rev-parse --show-toplevel)/pack-ops/session-config.json"
# Read one field, folding absent / malformed / unreachable -> the family default
isolation_mode="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("isolation_mode","read-write-only"))' "$cfg" 2>/dev/null || echo read-write-only)"
```

Every consumer — the spawn preflight, the reload commands (`/pack-startup`,
`/pack-refresh`), the selectors' read-modify-write, `/pack-status`, and the
intervention / review gates — uses this one idiom. `/pack-startup` and
`/pack-refresh` warm the value but are NOT the authority; the on-disk config
is. Absent / malformed / unreachable all fold to the family default:
`review_mode` → `itemized`, `intervention_mode` → `full`, `isolation_mode` →
`read-write-only`.

## Selectors + option cap

Set a mode through its chat selector: `/pack-review-mode`,
`/pack-intervention-mode`, or `/pack-isolation-mode` (Claude-only). On Claude a
selector presents the family's options through AskUserQuestion; other CLIs
present the same options as a numbered text menu, reading the reply. On a
`none` choice the selector shows an explicit risk warning, enforces the
`none` ↔ `none` coupling, then writes the value into the config; a missing
config is created with defaults plus the change.

AskUserQuestion presents 2–4 options per question. Review and intervention each
carry four values, within that cap. A fifth value in either family would exceed
the single-question cap and require a different presentation.

## Per-mode detail

Run `/pack-help` for the user-facing per-mode detail.
