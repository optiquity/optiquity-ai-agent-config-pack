---
name: pack-dashboard
description: Render and publish the pack frontier dashboard — a fresh single-page HTML snapshot of live pack work. On `/pack-dashboard` or a "generate the dashboard" request, run the dashboard-render procedure (the committed renderer scripts/dashboard-render.py build), which authors the shell, injects the complete state, and runs the complete verify floor before accepting the board; then publish the board to claude.ai in the foreground and record its URL.
allowed-tools: Read, Bash, Write
---

Produce a fresh dashboard render and publish it. On `/pack-dashboard` (or a plain
"generate the dashboard" request), invoke the committed renderer, then publish the
board and record its URL. The board is complete-or-loud-abort via the renderer's
`verify` floor, never silently short. Publishing is a foreground, orchestrator-only
step.

## Step 1 — Render

Run the `dashboard-render` procedure — i.e. run `python3 scripts/dashboard-render.py
build --repo-root <repo-root>` against `pack-ops/DASHBOARD-SPEC-PACK.md` and the live
repo. The renderer executes the spec's §2 recipe: it collects fresh state (committed
sources + a live git working-tree read + `pack-ops/session-state.json`, including the
complete session-state layer), builds the full/minimal payload, authors or reuses the
spec-fingerprinted shell `pack-ops/dashboard-approvals/dashboard-shell.html`, writes
`pack-ops/dashboard-approvals/dashboard.html`, and runs the complete-floor `verify`
inline. The write is atomic (temp, then verify, then rename on PASS): a shortfall exits
non-zero and leaves no board on disk — the render is never accepted short.

## Step 2 — Foreground publish

Publishing to claude.ai is Claude-only and orchestrator-only (a spawn-driven publish
is denied by the auto-mode classifier), so it runs in the foreground. The claude.ai
Artifact body-content is derived from the rendered
`pack-ops/dashboard-approvals/dashboard.html` on the fly — strip the outer HTML
document wrapper (the doctype, html, head, and body elements; the Artifact tool
supplies its own, and the page is ASCII-safe per the spec, so the stripped body
publishes cleanly). No separate body file is written — the body is derived from
`dashboard.html` each publish.

- **First publish of a new artifact:** publish the derived body; the first publish is
  the interactive permission gate. Record the returned URL into
  `pack-ops/dashboard-approvals/dashboard-url.txt` (one line).
- **Subsequent renders:** read the existing
  `pack-ops/dashboard-approvals/dashboard-url.txt` and republish the freshly-derived
  body to that SAME URL (republishing an already-approved artifact does not re-prompt).

On a CLI without the claude.ai publish capability, stop after the render: the rendered
`pack-ops/dashboard-approvals/dashboard.html` is the deliverable, opened locally; there
is no URL record to write.

## Step 3 — Commit

Stage and commit the approvals-dir files (user approval; automatic only under `none`
intervention per `pack-ops/OPERATING-MODES.md`). The first render commits all three
approvals-dir files together — `pack-ops/dashboard-approvals/dashboard-shell.html`,
`pack-ops/dashboard-approvals/dashboard.html`, and
`pack-ops/dashboard-approvals/dashboard-url.txt`. Later renders commit
`pack-ops/dashboard-approvals/dashboard.html` always, plus
`pack-ops/dashboard-approvals/dashboard-shell.html` only when a spec change flipped
its `spec-sha` (the shell was regenerated); the URL record is unchanged. Pack Chat
never auto-pushes; agents never commit.
