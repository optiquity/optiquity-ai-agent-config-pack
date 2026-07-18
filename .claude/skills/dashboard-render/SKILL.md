---
name: dashboard-render
description: Render a self-contained single-page HTML dashboard from a build-spec doc and live repo state. Generic and spec-driven — the caller hands the spec doc, the shell path, and the output path; behavior is whatever that spec declares. Reuses a spec-fingerprinted shell across renders, regenerating it only when the spec changes, and injects freshly-thinned state each render.
allowed-tools: Read, Bash, Write, Grep
---

Render one self-contained HTML dashboard page. This skill is generic and
spec-driven: its behavior is whatever build-spec doc the caller hands it. It
reads TWO inputs fresh on every render — the spec doc named by the caller and
live repo state — and emits one HTML page. It splits the render into a
state-INDEPENDENT shell — skeleton, CSS, render JS, and hash router — persisted
as a git-tracked file and reused across renders, plus live STATE collected
fresh, thinned, and injected every render. A spec change regenerates the shell;
a state change re-injects it; no STATE persists between renders.

## Step 1 — Read the inputs

- Read the build-spec doc the caller names, in full. For the pack frontier
  dashboard that spec is `pack-ops/DASHBOARD-SPEC-PACK.md`.
- Collect live repo state as the spec's data-source section directs: the
  committed source files plus a live git working-tree read taken now (so
  uncommitted, in-flight work appears).

## Step 2 — Resolve the tree and fingerprint the spec

Resolve every path from the render's own tree — no hardcoded absolute path, no
branch name:

```bash
ROOT="$(git rev-parse --show-toplevel)"
SPEC_SHA="$(git hash-object "$ROOT/pack-ops/DASHBOARD-SPEC-PACK.md")"
```

`git hash-object` hashes the working-tree spec, so an uncommitted spec edit also
counts as a change. `SPEC_SHA` is the reuse-or-regenerate key.

## Step 3 — Reuse or regenerate the shell

The shell is the persisted, state-independent HTML the caller names — for the
pack frontier dashboard, `pack-ops/dashboard-approvals/dashboard-shell.html`. It
is a complete HTML file carrying a provenance comment (stamping the spec's
`git hash-object`) and one inert state sentinel where the payload will go:

```html
<!-- pack-dashboard shell · spec: pack-ops/DASHBOARD-SPEC-PACK.md · spec-sha: <40-hex> -->
<script type="application/json" id="state">__PACK_DASHBOARD_STATE__</script>
```

- Read the shell's embedded `spec-sha`. If the shell file is absent, or its
  `spec-sha` differs from `SPEC_SHA`: **regenerate**. Otherwise: **reuse**.
- **Regenerate** — build the state-independent shell per the spec (its head/body
  skeleton, design system, render functions, and hash router, all reading only
  from the injected state), embed the `__PACK_DASHBOARD_STATE__` sentinel at the
  state element, stamp the provenance comment with `spec-sha: <SPEC_SHA>`, and
  Write it to the shell path.
- **Reuse** — Read the persisted shell as-is; do not rewrite it (a reuse render
  leaves the shell file byte-unchanged).

Make the shell's router boot defensive: it MUST treat the
`__PACK_DASHBOARD_STATE__` sentinel — or any `JSON.parse` failure on the state
element — as EMPTY state and render an idle page, so the persisted shell opens
cleanly on its own.

## Step 4 — Thin the live state and inject

- **Thin** the collected state per the spec's payload rules: in-window items
  keep their full records and deep plan; out-of-window items keep only the
  minimal fields the spec names. Which items are full vs minimal is
  spec-declared — this skill only applies the rule.
- **Serialize** the thinned state deterministically — sorted keys, no
  timestamps, no randomness — and escape `<`, `>`, `&` so it cannot break out of
  the state element.
- **Inject** by replacing the shell's `__PACK_DASHBOARD_STATE__` sentinel with
  the serialized state, then Write the result to the output path the caller
  names (for the pack frontier dashboard,
  `pack-ops/dashboard-approvals/dashboard.html`). Injection does not touch the
  shell file.

The spec's own requirements outrank any general guidance here. Identical (spec,
state) yields identical output.
