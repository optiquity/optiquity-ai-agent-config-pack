---
name: dashboard-render
description: Render a self-contained single-page HTML dashboard from a build-spec doc and live repo state. Generic and spec-driven — the caller hands the spec doc and the output path; behavior is whatever that spec declares. Reads fresh every render; persists nothing.
allowed-tools: Read, Bash, Write, Grep
---

Render one self-contained HTML dashboard page. This skill is generic and
spec-driven: its behavior is whatever build-spec doc the caller hands it. It
reads TWO inputs fresh on every render — the spec doc named by the caller and
live repo state — and emits one HTML page. It is stateless and cache-free:
nothing persists between renders, and a changed spec needs no change here.

## Step 1 — Read the inputs

- Read the build-spec doc the caller names, in full. For the pack frontier
  dashboard that spec is `pack-ops/DASHBOARD-SPEC-PACK.md`.
- Collect live repo state as the spec's data-source section directs: the
  committed source files plus a live git working-tree read taken now (so
  uncommitted, in-flight work appears).

## Step 2 — Follow the spec's build recipe

Execute the spec's build recipe exactly. In general that means: assemble one
state object from the collected sources; emit a single self-contained HTML file
(inline CSS + JS, data-URI images only, no external network references);
serialize the state deterministically (sorted keys, no timestamps, no
randomness) so identical state yields identical output; and render every page,
section, and field in whichever of full / degraded / removed form the current
state yields. The spec's own requirements outrank any general guidance here.

## Step 3 — Emit

Write the finished HTML page to the output path the caller names (for the pack
frontier dashboard, `pack-ops/dashboard-approvals/dashboard.html`). Persist no
intermediate artifact and no state between renders.
