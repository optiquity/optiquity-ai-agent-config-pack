---
name: pm-isolation-mode
description: Set the isolation mode — which agent classes spawn into an isolated worktree (read-write-only or full). Claude-only enforcement. Run to change which agent classes get an isolated worktree this session.
allowed-tools: Bash
---

Set the session's `isolation_mode`. This is a PM-chat-only selector; worktree
isolation is a Claude-only capability, so its enforcement is Claude-only. It
writes the choice to the per-clone config and takes effect at the next agent
spawn. See `docs/pack/PM-OPERATING-MODES.md` for the full behavior of each value.

**Enforcement is Claude-only.** On Codex/Antigravity selecting a mode records the
preference but is not hook-enforced (a documented convention, not a hard gate).

## Step 1 — Present the options

Present these two values, each with its one-line explanation, and let the user
choose:

- **read-write-only** (default) — only read-write agents (`coder`, `repo-ops`)
  spawn into an isolated worktree; read-only agents (reviewers, architects,
  planners, the auditor family, and the other report-only agents) spawn in the
  tree the work lives in.
- **full** — all agents (read-only included) spawn into an isolated worktree;
  an isolated agent runs git only in its own worktree or the PM-chat-injected
  commit workspace, reads target-tree files by absolute path, and returns on
  the async completion channel (clean-channel opt-in).

On Claude, present them through the native **AskUserQuestion** chooser (a `header`
of ≤12 chars; each option a 1–5-word `label` plus the explanation as its
`description`). On a CLI without that chooser, print the same two as a numbered
text menu and read the reply.

## Step 2 — Write the config

Write the chosen value into the per-clone config in the current worktree (the
checkout the PM chat runs in); a missing file is created with the defaults plus
the change:

```bash
top="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "pm mode selector: not inside a git working tree — cannot locate the session config" >&2; exit 1; }
cfg="$top/docs/project/pm-session-config.json"
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
cfg.setdefault("schema", "pm-session-config/1")
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

Confirm the new active mode to the user, then read the `### Isolation mode`
section of `docs/pack/PM-OPERATING-MODES.md` and present the Behavior entry for
the selected `isolation_mode` value so its active behavior is explicit in
context. Point to `/pm-help` for the per-mode detail.
