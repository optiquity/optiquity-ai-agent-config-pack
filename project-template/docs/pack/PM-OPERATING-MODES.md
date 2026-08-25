# PM operating modes — review / intervention / isolation

Self-contained SSOT for the PM chat's three operating-mode families. The PM chat
(the orchestrator) applies the active modes; spawned agents never read the
config — mode-dependent directives are injected into each spawn prompt by the
orchestrator. Modes govern the PM chat only.

## The three families

### Review mode — `review_mode` (default `itemized`)

Governs how you are asked to respond to the open items (questions, gaps,
expansions, decisions) that spawned agents surface in their reports.

| Value | Behavior |
|---|---|
| `itemized` (default) | Walk the open items one at a time. Per item: (1) enough context to understand the problem; (2) the agent's options (not the chat's); (3) the agent's recommendation only if it is evidence/logic-based, else state that none can be given. Exclude memory-based recommendations and any that defer or delay the work. This is current behavior. |
| `full` | Present all open items together in a single batch, each with as much detail as needed and the agent's evidence/logic-based recommendation (or an explicit "no recommendation"). Same memory/defer exclusion. |
| `hybrid` | Present the open items in multiple batches grouped by complexity — simple items batched together, complex items shown individually — each with full detail and the agent's evidence/logic-based recommendation. Same memory/defer exclusion. |
| `none` | No user review. For every surfaced open item the agent's evidence/logic-based recommendation is auto-accepted. Coupled to `none` intervention; shows an explicit risk warning at selection. Safe only because every agent recommendation must exist and be reliable. |

### Intervention mode — `intervention_mode` (default `full`)

Governs the pause / surface gates — the commit-approval gate, the reviewer-
triage gate, the planner-to-coder gate, and the design-review gate.

| Value | Behavior |
|---|---|
| `full` (default) | Every gate pauses for explicit input. This is current behavior. |
| `pre-coder` | Pauses at the pre-implementation gates (design review, planner-to-coder), then runs the coder → reviewer/fix cycle uninterrupted — pausing again only for an unplanned architect pass, or to stop / divert / reprioritize unplanned or later work. At other gates the PM chat accepts the agent's evidence-or-logic recommendation. The commit-approval gate still pauses (only `none` waives it). |
| `ambiguity` | The PM chat accepts the agent's evidence-or-logic recommendation at every gate EXCEPT where the agent surfaces genuine ambiguity (no reliable recommendation), which pauses. The commit-approval gate still pauses. |
| `none` | No pause / surface gate; the PM chat accepts every agent recommendation and auto-commits (see the safety boundary). |

### Isolation mode — `isolation_mode` (default `read-write-only`, Claude-only enforcement)

Governs which agent classes spawn into an isolated worktree. Worktree isolation
is a Claude-only capability, so its enforcement is Claude-only (see "Enforcement
by CLI"); the selector still records the preference on every CLI.

| Value | Behavior |
|---|---|
| `read-write-only` (default) | Only read-write agents (`coder`, `repo-ops`) spawn into an isolated worktree; read-only agents (reviewers, architects, planners, the auditor family, and the other report-only agents) spawn in the tree the work lives in. This is current behavior. |
| `full` | All agents — read-only included — spawn into an isolated worktree. An isolated agent runs git only in its own worktree or the PM-chat-injected commit workspace; the platform refuses git aimed at the main checkout or any tree under its path. Canonical facts (HEAD, dirty summary) arrive injected in the spawn prompt; target-tree files are read by absolute path. Clean-channel opt-in: isolated spawns return on the async completion channel (see the `full` isolation note in `docs/pack/PM-CHAT.md`). |

**How `full` executes.** The PM chat injects the canonical facts (HEAD SHA,
dirty-state summary) into every spawn prompt. The agent verifies its regime —
`pwd` shows an agent worktree; its own `git rev-parse HEAD` equals the injected
SHA; `git worktree list` cross-checks the canonical SHA — then runs all
committed-state git in its OWN worktree and reads target-tree files by absolute
path. On a base mismatch (a wrong-base worktree) the agent reports the
degradation and falls back to Read-tool verification of named canonical files;
it never attempts cross-tree git.

## Coupling — `none` ↔ `none`

Writing `review_mode: none` also sets `intervention_mode: none`, and writing
`intervention_mode: none` also sets `review_mode: none`. The two `none` states
are always paired — an unreviewed finding auto-applied under one family cannot
land while the other family still gates.

## Safety boundary — `none` intervention

`none` intervention authorizes PM chat auto-commit — a standing user-granted
override of the per-commit approval gate. The PM chat NEVER auto-pushes. Spawned
agents NEVER commit, in every mode — that boundary is absolute.

`isolation_mode` and the `intervention_mode` commit-approval gate are
mechanically backstopped by Claude-only PreToolUse hooks — see
`docs/pack/OPTIONAL-FEATURES.md`.

## Enforcement by CLI

All three selectors ship to every CLI root and record the chosen value. What
*backs* a mode then splits: cross-CLI **salience** (the PM chat honors the
recorded value on every CLI) vs Claude-only **hook enforcement** (a mechanical
backstop wired only in `.claude/settings.json`; Codex and Antigravity have no
equivalent).

- **`review_mode`** — cross-CLI salience only; no hook.
- **`intervention_mode`** — cross-CLI salience; its commit-approval gate is
  additionally Claude-only hook-enforced (a fresh per-commit approval token).
- **`isolation_mode`** — Claude-only enforcement. Worktree isolation is a
  Claude-only capability, so the under-isolated-spawn deny hook is Claude-only;
  on Codex/Antigravity the selector records the preference but it is not
  hook-gated (a documented convention, not a hard gate).

## The config file

The three modes live in a gitignored, per-clone (per-worktree when a clone has
multiple working trees) JSON config under `docs/project/` — a sibling of the
committed `docs/project/pm-session-state.json` snapshot, read only by the PM chat
(spawned agents never read it, so its absence in an isolated worktree is harmless
by construction). Schema `pm-session-config/1`; three string fields, each with a
default:

```json
{
  "schema": "pm-session-config/1",
  "review_mode": "itemized",
  "intervention_mode": "full",
  "isolation_mode": "read-write-only"
}
```

- **Missing / absent / malformed ⇒ defaults** — never an error, never a random
  value. The three defaults (`itemized` / `full` / `read-write-only`) equal
  current PM-chat behavior, so an unset config behaves as today.
- **Orchestrator-read-only** — read ONLY by the PM chat (the main tree); spawned
  agents never read it.
- **Not git-tracked** — so no CI check validates its content; the orchestrator
  validates at read time (missing / malformed ⇒ defaults).

## Reading the config

Re-read the active mode at each point it governs a decision — never a session-
start-cached value. A cached read can drift across context compaction, a long
session, or a background-session worktree, spawning agents under the wrong mode
(a silent correctness failure). Read-at-point-of-use holds nothing between disk
and decision, so nothing can drift.

Resolve the config at the CURRENT worktree — the checkout the PM chat runs in.
Derive the path at runtime; read one field, folding absent / malformed /
unreachable to the family default:

```bash
# Resolve the current-worktree config path
cfg="$(git rev-parse --show-toplevel)/docs/project/pm-session-config.json"
# Read one field, folding absent / malformed / unreachable -> the family default
isolation_mode="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1])).get("isolation_mode","read-write-only"))' "$cfg" 2>/dev/null || echo read-write-only)"
```

Every consumer — the spawn preflight, the reload commands (`/pm-startup`,
`/pm-refresh`), the selectors' read-modify-write, `/pm-status`, and the
intervention / review gates — uses this one idiom. `/pm-startup` and `/pm-refresh`
warm the value but are NOT the authority; the on-disk config is.

## Selectors + option cap

Set a mode through its chat selector: `/pm-review-mode`, `/pm-intervention-mode`,
or `/pm-isolation-mode` (Claude-only enforcement). On Claude a selector presents the family's
options through AskUserQuestion; other CLIs present the same options as a numbered
text menu, reading the reply. On a `none` choice the selector shows an explicit
risk warning, enforces the `none` ↔ `none` coupling, then writes the value into
the config; a missing config is created with defaults plus the change.

AskUserQuestion presents 2–4 options per question. Review and intervention each
carry four values, within that cap.

## Scope of `isolation_mode` — in-session spawns only

`isolation_mode` governs ONLY the in-session Agent-tool spawn path — the hook
that backstops it fires on Agent spawns (see `docs/pack/OPTIONAL-FEATURES.md`).
The shipped `agent-run.sh` launcher isolates per its own `--worktree` flag and is
NOT reached by this config or the hook; setting `isolation_mode: full` does not
govern an `agent-run.sh` launch.

## Per-mode detail

Run `/pm-help` for the user-facing per-mode detail.
