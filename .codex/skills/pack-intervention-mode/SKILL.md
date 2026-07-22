---
name: pack-intervention-mode
description: Set the intervention mode — how much Pack Chat pauses at its gates (full, pre-coder, ambiguity, or none). Run to change how often the workflow pauses for your input this session.
allowed-tools: Bash
---

Set the session's `intervention_mode`. This is a Pack-Chat-only selector; it
writes the choice to the per-clone config and takes effect at the next gate. See
`pack-ops/OPERATING-MODES.md` for the full behavior of each value.

## Step 1 — Present the options

Present these four values, each with its one-line explanation, and let the user
choose:

- **full** (default) — every gate (commit approval, reviewer triage,
  planner-to-coder, design review) pauses for explicit input.
- **pre-coder** — pause at the pre-implementation gates, then run the
  coder → reviewer/fix cycle uninterrupted; the commit-approval gate still pauses.
- **ambiguity** — accept the agent's evidence-or-logic recommendation at every
  gate except where the agent surfaces genuine ambiguity; the commit-approval
  gate still pauses.
- **none** — no pause gates; accept every agent recommendation and auto-commit.

On Claude, present them through the native **AskUserQuestion** chooser (a `header`
of ≤12 chars; each option a 1–5-word `label` plus the explanation as its
`description`). On a CLI without that chooser, print the same four as a numbered
text menu and read the reply.

## Step 2 — Handle `none`

If the user picks `none`, first show an explicit risk warning: `none` disables
every pause gate AND, through the coupling below, all user review, and authorizes
Pack-Chat auto-commit (never auto-push; agents never commit). Require an explicit
confirmation before writing. Selecting `none` also sets `review_mode` to `none`
(the `none` ↔ `none` coupling).

## Step 3 — Write the config

Write the chosen value into `pack-ops/session-config.json` in the current
worktree (the checkout Pack Chat runs in); a missing file is created with the
defaults plus the change:

```bash
top="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "pack mode selector: not inside a git working tree — cannot locate pack-ops/session-config.json" >&2; exit 1; }
cfg="$top/pack-ops/session-config.json"
CHOICE="full"   # full | pre-coder | ambiguity | none — the user's selection
python3 - "$cfg" "$CHOICE" <<'PY'
import json, os, sys
path, choice = sys.argv[1], sys.argv[2]
try:
    cfg = json.load(open(path))
    if not isinstance(cfg, dict):
        cfg = {}
except Exception:
    cfg = {}
cfg.setdefault("schema", "pack-session-config/1")
cfg.setdefault("review_mode", "itemized")
cfg.setdefault("intervention_mode", "full")
cfg.setdefault("isolation_mode", "read-write-only")
cfg["intervention_mode"] = choice
if choice == "none":
    cfg["review_mode"] = "none"   # none <-> none coupling
os.makedirs(os.path.dirname(path), exist_ok=True)
json.dump(cfg, open(path, "w"), indent=2, sort_keys=False)
print("intervention_mode ->", choice)
PY
```

## Step 4 — Confirm

Confirm the new active mode to the user, then read the `### Intervention mode`
section of `pack-ops/OPERATING-MODES.md` and present the Behavior entry for
the selected `intervention_mode` value so its active behavior is explicit in
context. Point to `/pack-help` for the per-mode detail.
