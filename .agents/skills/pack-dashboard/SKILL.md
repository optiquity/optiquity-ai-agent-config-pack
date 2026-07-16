---
name: pack-dashboard
description: Render and publish the pack frontier dashboard — a fresh single-page HTML snapshot of live pack work. Run for an at-a-glance view of the backlog frontier and each item's pipeline. Renders in a background worktree, merges back, then publishes.
allowed-tools: Task, Bash, Read
---

Produce a fresh dashboard render and publish it. The render is a read-write step
(it writes a tracked file), so it runs in an isolated worktree and reaches the
main tree through the standard patch → apply → commit merge-back — never a direct
worktree write into the main checkout. Publishing is a foreground,
orchestrator-only step.

## Step 1 — Background render (isolated worktree)

Spawn a BACKGROUND read-write render coder with `isolation:"worktree"`. Prompt it
to run the `dashboard-render` skill against `pack-ops/DASHBOARD-SPEC-PACK.md` and
the live repo, and to write the page to
`pack-ops/dashboard-approvals/dashboard.html` in its worktree. It writes its
implementation report to the handoff dir and returns with NO patch (the pack
read-write contract).

## Step 2 — Sanity + merge-back

Run the render's lightweight artifact-sanity check inside that worktree (the
render is a deterministic, spec-conformant generation). On clean, SendMessage
the render coder to emit the patch (`git diff > <handoff>/changes.patch`), then
apply it to the main tree (`git apply --check`, then `git apply`) so
`pack-ops/dashboard-approvals/dashboard.html` exists in the main checkout.

## Step 3 — Foreground publish (main tree)

Publishing to claude.ai is Claude-only and orchestrator-only (a spawn-driven
publish is denied by the auto-mode classifier), so it runs in the foreground
from the main tree:

- **First publish of a new artifact:** publish `dashboard.html`; the first
  publish is the interactive permission gate. Record the returned URL into
  `pack-ops/dashboard-approvals/dashboard-url.txt` (one line).
- **Subsequent renders:** read the existing
  `pack-ops/dashboard-approvals/dashboard-url.txt` and republish to that SAME
  URL (republishing an already-approved artifact does not re-prompt).

On a CLI without the claude.ai publish capability, stop after the merge-back: the
rendered `pack-ops/dashboard-approvals/dashboard.html` is the deliverable, opened
locally; there is no URL record to write.

## Step 4 — Commit

Stage and commit the approvals-dir files (user approval; automatic only under
`none` intervention per `pack-ops/OPERATING-MODES.md`). The first render commits
both approvals-dir files together; later renders commit only the updated render
(the URL record is unchanged). Pack Chat never auto-pushes; agents never commit.
