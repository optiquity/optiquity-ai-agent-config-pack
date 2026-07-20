---
name: dashboard-render
description: Render a self-contained single-page HTML dashboard directly from its build spec, in the main tree. Read the spec, collect fresh state (committed sources + a live git working-tree read + the session-state snapshot, including the complete session-state layer), select each record's full-or-minimal tier, inject the state into a spec-fingerprinted HTML shell (reused when its spec-sha matches the live spec, regenerated otherwise), write the page, and run a render-time completeness self-check before the page is accepted. The render happens in place, fresh on every request.
allowed-tools: Read, Bash, Write, Grep
---

Render one self-contained HTML dashboard page for the pack frontier, directly in
the main tree: the actor holding this skill reads the build-spec and renders the
page itself, fresh on every request. Read two inputs fresh every render — the
build-spec doc the caller names (for the pack frontier dashboard,
`pack-ops/DASHBOARD-SPEC-PACK.md`) and live repo state — and emit one HTML page.

The spec is the authority. Do not restate its substance here; execute its §2
recipe in full. This skill names the procedure, the output, and the render-time
self-check only.

## Step 1 — Read the spec and collect fresh state (§2 step 1, §3)

Read the spec, then assemble the state object per its §3 state → source map, all
read fresh:

- **Committed / canonical:** the `/backlog/` tree, the `/changelog/` tree,
  `README.md`, `CLAUDE.md` § Pack memory, `PACK-AGENTS.md`.
- **Live git working-tree read** (`git status` + `git worktree list` at render
  time) for the `inflight` block — this is what pulls in uncommitted work.
- **`pack-ops/session-state.json`**, read for the COMPLETE session-state layer:
  `boundary_commit`, `active[]`, `in_flight_agents[]`, `queue[]`,
  `parallelization`, `wave`, `cycle_position`, `pending_decisions[]`, and the
  derived `motion[]`, honoring the spec's prose-tolerance rule for free-text
  fields.

Never cache state between renders (R2); collect the entire payload fresh.

## Step 2 — Select the tier and build the payload (§3 payload thinning)

Select the deterministic full set and emit every `bds{}` record with its
`tier:"full"|"minimal"` field per the spec: the full set is every non-terminal BD
plus the 10 most-recently-`Resolved`, each carrying a source-anchored body drawn
from its own live backlog entry; everything else is minimal. Populate the plans
and section floors the same way. Selection is a deterministic recompute
every render — never a reuse of a prior payload, never a hand-authored count.

## Step 3 — Reuse or regenerate the fingerprinted shell (§2 step 4)

The shell is the state-independent HTML (skeleton, design system, render JS, hash
router), persisted as the git-tracked file the caller names — for the pack
frontier dashboard, `pack-ops/dashboard-approvals/dashboard-shell.html`. It pins a
provenance comment at line 2 and one inert state element:

```html
<!-- pack-dashboard shell · spec: pack-ops/DASHBOARD-SPEC-PACK.md · spec-sha: <40-hex> -->
<script type="application/json" id="state">__PACK_DASHBOARD_STATE__</script>
```

- `spec-sha` = `git hash-object` of the build-spec doc. Read the shell's embedded
  `spec-sha`. If the shell is absent, or its `spec-sha` differs from the live
  value: **regenerate** — author the state-independent skeleton + CSS + render JS
  + router per the spec, embed the `__PACK_DASHBOARD_STATE__` sentinel at the
  state element, stamp the provenance comment with the live `spec-sha`, and Write
  it to the shell path. Otherwise: **reuse** it byte-unchanged.
- Make the router boot defensive: treat the `__PACK_DASHBOARD_STATE__` sentinel —
  or any `JSON.parse` failure on the state element — as EMPTY state and render an
  idle page, so the persisted shell opens cleanly on its own.

Inject the fresh state into the fingerprint-matching shell (or a minimal fail-safe
shell when none matches) and Write `pack-ops/dashboard-approvals/dashboard.html`.
Serialize with sorted keys and escape only `<` on the JSON-in-`<script>` path
(§2 step 3).

## Step 4 — Render-time completeness self-check (before the page is accepted)

This is your own check on your own render, run BEFORE the board is accepted or
published:

- **Session-state layer — never silently short.** Confirm the rendered `#state`
  represents EVERY session-state-layer field the snapshot carries content for:
  `boundary_commit`, `active[]`, `in_flight_agents[]`, `queue[]`,
  `parallelization`, `wave`, `cycle_position`, `pending_decisions[]`, and derived
  `motion[]`. Each renders full / degraded / removed per R11 presence — but a
  field whose `pack-ops/session-state.json` source HAS content must NEVER be
  silently dropped. A missing session-layer field when the snapshot carries it is
  a fail-loud abort.
- **Conformance floor.** Confirm the payload carries exactly `|E_full|` records
  with `tier:"full"`, each with a source-anchored body; the plans and section
  floors hold; the status vocabulary is closed; parse coverage is 100%.

On any shortfall, ABORT and regenerate — never accept or publish a short or
half-rendered board. The spec's own requirements outrank any general guidance
here; identical (spec, state) yields identical output.
