---
name: pack-isolation-mode
description: Set the isolation mode — which agent classes spawn into an isolated worktree (read-write-only or full). Claude-only selector. Run to change which agent classes get an isolated worktree this session.
allowed-tools: Bash
---

Set the session's `isolation_mode`. This is a Pack-Chat-only, Claude-only
selector (worktree isolation is a Claude-only capability); it writes the choice
to the per-clone config and takes effect at the next agent spawn. See
`pack-ops/OPERATING-MODES.md` for the full behavior of each value.

## Step 1 — Present the options

Present these two values, each with its one-line explanation, and let the user
choose:

- **read-write-only** (default) — only read-write agents (coders, fix-coders)
  spawn into an isolated worktree; read-only agents (reviewers, architects,
  planners, docs-researchers) spawn in the tree the work lives in.
- **full** — all agents (read-only included) spawn into an isolated worktree,
  then `cd` to the target tree.

On Claude, present them through the native **AskUserQuestion** chooser (a `header`
of ≤12 chars; each option a 1–5-word `label` plus the explanation as its
`description`). On a CLI without that chooser, print the same two as a numbered
text menu and read the reply.

## Step 2 — Write the config

Write the chosen value into `pack-ops/session-config.json` in the current
worktree (the checkout Pack Chat runs in); a missing file is created with the
defaults plus the change:

```bash
top="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "pack mode selector: not inside a git working tree — cannot locate pack-ops/session-config.json" >&2; exit 1; }
cfg="$top/pack-ops/session-config.json"
CHOICE="read-write-only"   # read-write-only | full — the user's selection
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
cfg["isolation_mode"] = choice
os.makedirs(os.path.dirname(path), exist_ok=True)
json.dump(cfg, open(path, "w"), indent=2, sort_keys=False)
print("isolation_mode ->", choice)
PY
```

## Step 3 — Confirm

Confirm the new active mode to the user and point to `/pack-help` for the
per-mode detail.
