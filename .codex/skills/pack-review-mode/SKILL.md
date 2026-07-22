---
name: pack-review-mode
description: Set the review mode — how the user is asked to respond to the open items agents surface (itemized, full, hybrid, or none). Run to change how open-item review is presented for this session.
allowed-tools: Bash
---

Set the session's `review_mode`. This is a Pack-Chat-only selector; it writes the
choice to the per-clone config and takes effect at the next review gate. See
`pack-ops/OPERATING-MODES.md` for the full behavior of each value.

## Step 1 — Present the options

Present these four values, each with its one-line explanation, and let the user
choose:

- **itemized** (default) — walk the open items one at a time, each with context,
  the agent's options, and its evidence-or-logic recommendation.
- **full** — present all open items together in one batch, each fully detailed.
- **hybrid** — batch simple items together and show complex items individually.
- **none** — no user review; every agent's evidence-or-logic recommendation is
  auto-accepted.

On Claude, present them through the native **AskUserQuestion** chooser (a `header`
of ≤12 chars; each option a 1–5-word `label` plus the explanation as its
`description`). On a CLI without that chooser, print the same four as a numbered
text menu and read the reply.

## Step 2 — Handle `none`

If the user picks `none`, first show an explicit risk warning: `none` disables
user review AND, through the coupling below, all intervention pause gates, and
authorizes Pack-Chat auto-commit (never auto-push; agents never commit). Require
an explicit confirmation before writing. Selecting `none` also sets
`intervention_mode` to `none` (the `none` ↔ `none` coupling).

## Step 3 — Write the config

Write the chosen value into `pack-ops/session-config.json` in the current
worktree (the checkout Pack Chat runs in); a missing file is created with the
defaults plus the change:

```bash
top="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "pack mode selector: not inside a git working tree — cannot locate pack-ops/session-config.json" >&2; exit 1; }
cfg="$top/pack-ops/session-config.json"
CHOICE="itemized"   # itemized | full | hybrid | none — the user's selection
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
cfg["review_mode"] = choice
if choice == "none":
    cfg["intervention_mode"] = "none"   # none <-> none coupling
os.makedirs(os.path.dirname(path), exist_ok=True)
json.dump(cfg, open(path, "w"), indent=2, sort_keys=False)
print("review_mode ->", choice)
PY
```

## Step 4 — Confirm

Confirm the new active mode to the user, then read the `### Review mode`
section of `pack-ops/OPERATING-MODES.md` and present the Behavior entry for
the selected `review_mode` value so its active behavior is explicit in
context. Point to `/pack-help` for the per-mode detail.
