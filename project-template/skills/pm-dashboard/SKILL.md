---
name: pm-dashboard
description: Render and publish the project frontier dashboard — a fresh single-page HTML snapshot of live project work. On `/pm-dashboard` or a "generate the dashboard" request, run the dashboard-render procedure (the committed client renderer `python3 scripts/pm-dashboard-render.py build`), which authors the shell, injects the complete state, and runs the complete verify floor before accepting the board; then publish the board to claude.ai in the foreground and record its URL. Coexists with the markdown STATUS.md snapshot.
allowed-tools: Read, Bash, Write
---

Produce a fresh dashboard render and publish it. On `/pm-dashboard` (or a plain
"generate the dashboard" request), invoke the committed client renderer, then publish
the board and record its URL. The board is complete-or-loud-abort via the renderer's
`verify` floor, never silently short. Publishing is a foreground, orchestrator-only
step. This HTML board is an additional view — it coexists with the markdown STATUS.md
snapshot, which stays.

## Step 1 — Render

Run the dashboard-render procedure — i.e. run `python3 scripts/pm-dashboard-render.py
build --repo-root <repo-root>` against the project's build spec and the live repo. The
renderer executes the spec recipe: it collects fresh state (committed sources + a live
git working-tree read + `docs/project/pm-session-state.json`, including the session-state
layer), builds the full/minimal payload with a per-record `tier` field, authors or reuses
the spec-fingerprinted shell, writes the board, and runs the complete-floor `verify`
inline. The write is atomic (temp, then verify, then rename on PASS): a shortfall exits
non-zero and leaves no board on disk — the render is never accepted short.

The renderer writes into the approvals directory. That directory **does not exist yet** in
a fresh project — it is **created when a board first renders** (the renderer makes it on the
first build), so there is nothing to add to the template. The full approvals-directory
contract — the three-file set, the spec-fingerprinted shell reuse, and the repository-hygiene
attributes set up with the first real board — is documented in the build spec at
docs/pack/PM-DASHBOARD-SPEC.md; read it there rather than restating it here.

## Step 2 — Foreground publish

Publishing to claude.ai is Claude-only and orchestrator-only (a spawn-driven publish is
denied by the auto-mode classifier), so it runs in the foreground. The claude.ai Artifact
body-content is derived from the rendered board on the fly — strip the outer HTML document
wrapper (the doctype, html, head, and body elements; the Artifact tool supplies its own,
and the page is ASCII-safe per the spec, so the stripped body publishes cleanly). No
separate body file is written — the body is derived from the rendered board each publish.

- **First publish of a new artifact:** publish the derived body; the first publish is the
  interactive permission gate. Record the returned URL into the approvals directory's
  one-line URL record.
- **Subsequent renders:** read the existing URL record and republish the freshly-derived
  body to that SAME URL (republishing an already-approved artifact does not re-prompt).

On a CLI without the claude.ai publish capability, stop after the render: the rendered
board is the deliverable, opened locally; there is no URL record to write.

## Step 3 — Commit

Stage and commit the approvals-directory files under the project's normal commit-approval
gate. The first render commits all three approvals-directory files together — the shell,
the board, and the URL record. Later renders commit the board always, plus the shell only
when a spec change flipped its `spec-sha` (the shell was regenerated); the URL record is
unchanged. Agents never auto-commit.
