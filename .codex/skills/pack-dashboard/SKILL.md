---
name: pack-dashboard
description: Render and publish the pack frontier dashboard — a fresh single-page HTML snapshot of live pack work. On `/pack-dashboard` or a "generate the dashboard" request, Pack Chat reads pack-ops/DASHBOARD-SPEC-PACK.md and renders the full board itself in the main tree via the dashboard-render procedure, runs the render-time completeness self-check, then publishes the artifact and records its URL. The render happens directly, fresh every time.
allowed-tools: Read, Bash, Write
---

Produce a fresh dashboard render and publish it, directly. On `/pack-dashboard`
(or a plain "generate the dashboard" request), the orchestrator reads the build
spec and renders the full board itself in the main tree, fresh every time. The
board is conformant-or-loud-abort via the render-time self-check, never silently
short. Publishing is a foreground, orchestrator-only step.

## Step 1 — Render (in the main tree)

Read `pack-ops/DASHBOARD-SPEC-PACK.md` and run the `dashboard-render` procedure
against it and the live repo. That procedure executes the spec's §2 recipe in
full: it collects fresh state (committed sources + a live git working-tree read +
`pack-ops/session-state.json`, including the complete session-state layer), builds
the full/minimal payload, reuses the spec-fingerprinted shell
`pack-ops/dashboard-approvals/dashboard-shell.html` when its `spec-sha` matches the
live spec (regenerating it otherwise), writes
`pack-ops/dashboard-approvals/dashboard.html`, and runs the render-time
completeness self-check. A shortfall at the self-check regenerates the render — it
is never accepted short.

## Step 2 — Foreground publish (main tree)

Publishing to claude.ai is Claude-only and orchestrator-only (a spawn-driven
publish is denied by the auto-mode classifier), so it runs in the foreground from
the main tree:

- **First publish of a new artifact:** publish `dashboard.html`; the first publish
  is the interactive permission gate. Record the returned URL into
  `pack-ops/dashboard-approvals/dashboard-url.txt` (one line).
- **Subsequent renders:** read the existing
  `pack-ops/dashboard-approvals/dashboard-url.txt` and republish to that SAME URL
  (republishing an already-approved artifact does not re-prompt).

On a CLI without the claude.ai publish capability, stop after the render: the
rendered `pack-ops/dashboard-approvals/dashboard.html` is the deliverable, opened
locally; there is no URL record to write.

## Step 3 — Commit

Stage and commit the approvals-dir files (user approval; automatic only under
`none` intervention per `pack-ops/OPERATING-MODES.md`). The first render commits
all three approvals-dir files together —
`pack-ops/dashboard-approvals/dashboard-shell.html`,
`pack-ops/dashboard-approvals/dashboard.html`, and
`pack-ops/dashboard-approvals/dashboard-url.txt`. Later renders commit
`pack-ops/dashboard-approvals/dashboard.html` always, plus
`pack-ops/dashboard-approvals/dashboard-shell.html` only when a spec change flipped
its `spec-sha` (the shell was regenerated); the URL record is unchanged. Pack Chat
never auto-pushes; agents never commit.
