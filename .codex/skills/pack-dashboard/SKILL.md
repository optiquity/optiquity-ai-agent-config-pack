---
name: pack-dashboard
description: Render and publish the pack frontier dashboard — a fresh single-page HTML snapshot of live pack work driven by the committed build/verify script. Run for an at-a-glance view of the backlog frontier and each item's pipeline. Renders in a background worktree, gates the render on the script's fail-closed verify plus the mechanical CI floor, merges back, then publishes.
allowed-tools: Task, Bash, Read
---

Produce a fresh dashboard render and publish it. The render is a read-write step
(it writes a tracked file), so it runs in an isolated worktree and reaches the
main tree through the standard patch → apply → commit merge-back — never a direct
worktree write into the main checkout. The load-bearing state is produced by the
ONE committed build script and floored by its own fail-closed oracle, so the
render is conformant-or-loud-abort — never silently short. Publishing is a
foreground, orchestrator-only step.

## Step 1 — Background render (isolated worktree)

Spawn a BACKGROUND read-write render coder with `isolation:"worktree"`. Prompt it
to run the `dashboard-render` skill against `pack-ops/DASHBOARD-SPEC-PACK.md` and
the live repo: reuse or regenerate the fingerprinted shell
`pack-ops/dashboard-approvals/dashboard-shell.html` (per the `{spec-sha,
structure-sha}` pair), run `scripts/dashboard-build.py build` to produce the
deterministic state into `pack-ops/dashboard-approvals/dashboard.html`, and
confirm the render with `scripts/dashboard-build.py verify`, all written in its
worktree. It writes its implementation report to the handoff dir and returns with
NO patch (the pack read-write contract).

## Step 2 — Gate + merge-back

Before accepting the render, gate it on both the render-time oracle and the
mechanical CI floor:

- **Render-time oracle.** Confirm `scripts/dashboard-build.py verify` exited 0 in
  the worktree — the full set is wholly covered (every deterministic full-set
  member carries a source-anchored `tier:"full"` body), the plans and section
  floors hold, the render's `{spec-sha, structure-sha}` pair matches the live
  contracts, the status vocabulary is closed, and parse coverage is 100%.
- **Mechanical CI floor.** Run `PACK_VALIDATE_DEEP=1 python3
  scripts/validate-pack.py` and confirm the mechanical DEEP floor (Check 89)
  passes — it re-derives the full set independently and floors the committed
  render, so a skipped or faked oracle is caught. A shortfall at either gate
  means the render is regenerated, never committed short.

On clean, SendMessage the render coder to emit the patch
(`git diff > <handoff>/changes.patch`), then apply it to the main tree (`git
apply --check`, then `git apply`) so
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
`none` intervention per `pack-ops/OPERATING-MODES.md`). The build script itself
is committed source — regenerated only by a reviewed edit on a spec or
format-contract change, paired with the shell on the same `{spec-sha,
structure-sha}` fingerprint — and lands through its own review cycle, not this
approvals-dir commit. The first render commits all three approvals-dir files
together — `pack-ops/dashboard-approvals/dashboard-shell.html`,
`pack-ops/dashboard-approvals/dashboard.html`, and
`pack-ops/dashboard-approvals/dashboard-url.txt`. Later renders commit
`pack-ops/dashboard-approvals/dashboard.html` always, plus
`pack-ops/dashboard-approvals/dashboard-shell.html` only when a spec or
format-contract change flipped a fingerprint (the shell was regenerated); the URL
record is unchanged. Pack Chat never auto-pushes; agents never commit.
